"""Ledgerline API — authenticated, tenant-scoped, observable."""

from __future__ import annotations

import os
import threading
import time
import uuid
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Request, Response, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from psycopg.types.json import Jsonb
from starlette.exceptions import HTTPException as StarletteHTTPException

from audit import write_admin_audit
from auth import AdminPrincipal, Principal, require_admin, require_tenant
from config import ConfigError, Settings, load_settings
from db import close_pool, connection, init_pool, ping
from logging_setup import configure_logging
from schema import apply_schema
from telemetry import metrics_payload, observe_request

logger = configure_logging()
ENV = os.getenv("ENVIRONMENT", "local")
_settings: Settings | None = None
_heavy_report_sem: threading.BoundedSemaphore | None = None

app = FastAPI(title="Ledgerline API", version="0.5.0")


@app.middleware("http")
async def observability_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
    trace_id = request.headers.get("x-trace-id") or request_id
    request.state.request_id = request_id
    request.state.trace_id = trace_id
    started = time.perf_counter()
    response: Response | None = None
    status_code = 500
    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    finally:
        duration_ms = (time.perf_counter() - started) * 1000.0
        principal = getattr(request.state, "principal", None)
        tenant = getattr(principal, "tenant_id", None) or "none"
        route = request.url.path
        # Normalize record id paths for metric cardinality.
        endpoint = route
        if route.startswith("/records/") and route.count("/") == 2:
            endpoint = "/records/{id}"
        observe_request(
            endpoint=endpoint,
            method=request.method,
            status_code=status_code,
            tenant=tenant,
            duration_s=duration_ms / 1000.0,
        )
        logger.info(
            "request_complete",
            extra={
                "request_id": request_id,
                "trace_id": trace_id,
                "tenant": tenant,
                "route": route,
                "method": request.method,
                "status": status_code,
                "duration_ms": round(duration_ms, 2),
                "env": ENV,
            },
        )
        if response is not None:
            response.headers["X-Request-Id"] = request_id
            response.headers["X-Trace-Id"] = trace_id


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "request_id": getattr(request.state, "request_id", None)},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"error": "validation_error", "request_id": getattr(request.state, "request_id", None)},
    )


@app.on_event("startup")
def on_startup() -> None:
    global _settings, _heavy_report_sem
    try:
        settings = load_settings()
    except ConfigError as exc:
        raise RuntimeError(str(exc)) from exc
    _settings = settings
    _heavy_report_sem = threading.BoundedSemaphore(settings.heavy_report_max_concurrent)
    init_pool(settings)
    apply_schema()
    logger.info(
        "ledgerline_startup schema_ready=true heavy_report_max_concurrent=%s",
        settings.heavy_report_max_concurrent,
        extra={"env": ENV},
    )


@app.on_event("shutdown")
def on_shutdown() -> None:
    close_pool()


@app.get("/health")
def liveness():
    """Process liveness — does not check dependencies."""
    return {"status": "ok"}


@app.get("/ready")
def readiness():
    """Readiness — verifies database connectivity."""
    try:
        ping()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="database_unavailable",
        )
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    payload, content_type = metrics_payload()
    return Response(content=payload, media_type=content_type)


@app.post("/records", status_code=status.HTTP_201_CREATED)
def create_record(
    payload: dict[str, Any],
    principal: Principal = Depends(require_tenant),
):
    with connection() as conn:
        row = conn.execute(
            """
            INSERT INTO records (tenant_id, payload)
            VALUES (%s, %s)
            RETURNING id
            """,
            (principal.tenant_id, Jsonb(payload)),
        ).fetchone()
    return {"id": row[0]}


@app.get("/records")
def list_records(
    search: str = Query(default=""),
    limit: int = Query(default=50, ge=1, le=200),
    principal: Principal = Depends(require_tenant),
):
    # Empty search → indexed tenant list with LIMIT (load-path). ILIKE only when asked.
    with connection(autocommit=True) as conn:
        if search:
            rows = conn.execute(
                """
                SELECT id, payload, created_at
                FROM records
                WHERE tenant_id = %s
                  AND payload::text ILIKE %s
                ORDER BY id DESC
                LIMIT %s
                """,
                (principal.tenant_id, f"%{search}%", limit),
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT id, payload, created_at
                FROM records
                WHERE tenant_id = %s
                ORDER BY id DESC
                LIMIT %s
                """,
                (principal.tenant_id, limit),
            ).fetchall()
    return [
        {"id": r[0], "payload": r[1], "created_at": r[2]}
        for r in rows
    ]


@app.get("/records/{record_id}")
def get_record(
    record_id: int,
    principal: Principal = Depends(require_tenant),
):
    with connection(autocommit=True) as conn:
        row = conn.execute(
            """
            SELECT id, tenant_id, payload
            FROM records
            WHERE id = %s AND tenant_id = %s
            """,
            (record_id, principal.tenant_id),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not_found")
    return {"id": row[0], "tenant_id": row[1], "payload": row[2]}


@app.get("/reports/heavy")
def heavy_report(principal: Principal = Depends(require_tenant)):
    """
    Expensive self-join kept for Cobalt noisy-neighbour drills.
    Bounded concurrency + shorter statement_timeout so other tenants keep headroom.
    """
    if _heavy_report_sem is None or _settings is None:
        raise HTTPException(status_code=503, detail="not_ready")
    acquired = _heavy_report_sem.acquire(blocking=False)
    if not acquired:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="heavy_report_concurrency_limit",
        )
    try:
        timeout_ms = _settings.heavy_report_statement_timeout_ms
        # Non-autocommit so SET LOCAL applies to the heavy query transaction.
        with connection(autocommit=False) as conn:
            conn.execute(f"SET LOCAL statement_timeout = {int(timeout_ms)}")
            try:
                count = conn.execute(
                    """
                    SELECT count(*)
                    FROM records r1
                    JOIN records r2 ON r1.tenant_id = r2.tenant_id
                    WHERE r1.tenant_id = %s
                    """,
                    (principal.tenant_id,),
                ).fetchone()[0]
            except Exception as exc:
                # Statement timeout / cancel → 504 so clients back off without 500 storms.
                logger.warning(
                    "heavy_report_failed tenant=%s err=%s",
                    principal.tenant_id,
                    type(exc).__name__,
                )
                raise HTTPException(
                    status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                    detail="heavy_report_timeout",
                ) from exc
        return {"tenant": principal.tenant_id, "pairs": count}
    finally:
        _heavy_report_sem.release()


@app.delete("/admin/tenants/{tenant_id}")
def delete_tenant(
    tenant_id: str,
    request: Request,
    admin: AdminPrincipal = Depends(require_admin),
):
    request_id = getattr(request.state, "request_id", None)
    try:
        with connection() as conn:
            result = conn.execute(
                "DELETE FROM records WHERE tenant_id = %s",
                (tenant_id,),
            )
            deleted = result.rowcount
        write_admin_audit(
            actor=admin.actor,
            action="delete_tenant_records",
            target_tenant=tenant_id,
            request_id=request_id,
            outcome="success",
            detail={"deleted_rows": deleted},
        )
        logger.info(
            "admin_action",
            extra={
                "request_id": request_id,
                "tenant": tenant_id,
                "route": f"/admin/tenants/{tenant_id}",
                "method": "DELETE",
                "status": 200,
                "env": ENV,
            },
        )
        return {"deleted": tenant_id, "deleted_rows": deleted}
    except Exception as exc:
        write_admin_audit(
            actor=admin.actor,
            action="delete_tenant_records",
            target_tenant=tenant_id,
            request_id=request_id,
            outcome="error",
            reason="exception",
            detail={"error_type": type(exc).__name__},
        )
        raise


@app.get("/admin/audit")
def list_audit(
    limit: int = Query(default=50, ge=1, le=200),
    admin: AdminPrincipal = Depends(require_admin),
):
    with connection(autocommit=True) as conn:
        rows = conn.execute(
            """
            SELECT id, created_at, actor, action, target_tenant, request_id, outcome, reason, detail
            FROM admin_audit_events
            ORDER BY id DESC
            LIMIT %s
            """,
            (limit,),
        ).fetchall()
    from audit import audit_to_public_dict

    return [audit_to_public_dict(r) for r in rows]
