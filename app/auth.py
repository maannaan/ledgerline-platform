"""Authentication and authorization. Tenant identity is server-derived."""

from __future__ import annotations

import hashlib
import hmac
import secrets
from dataclasses import dataclass
from typing import Annotated, Optional

from fastapi import Depends, Header, HTTPException, Query, Request, status

from audit import write_admin_audit
from config import Settings, load_settings
from db import connection


@dataclass(frozen=True)
class Principal:
    tenant_id: str
    role: str
    key_id: int
    label: str


@dataclass(frozen=True)
class AdminPrincipal:
    actor: str = "platform_admin"


def hash_api_key(raw_key: str, pepper: str) -> str:
    return hashlib.sha256(f"{pepper}:{raw_key}".encode("utf-8")).hexdigest()


def generate_api_key() -> str:
    return f"ll_{secrets.token_urlsafe(32)}"


def _extract_bearer(authorization: Optional[str]) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return token.strip()


def resolve_principal(raw_key: str, settings: Settings) -> Principal:
    key_hash = hash_api_key(raw_key, settings.api_key_pepper)
    with connection(autocommit=True) as conn:
        row = conn.execute(
            """
            SELECT id, tenant_id, role, label
            FROM api_keys
            WHERE key_hash = %s AND revoked_at IS NULL
            """,
            (key_hash,),
        ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return Principal(
        key_id=row[0],
        tenant_id=row[1],
        role=row[2],
        label=row[3],
    )


def get_settings() -> Settings:
    return load_settings()


def require_tenant(
    request: Request,
    authorization: Annotated[Optional[str], Header()] = None,
    x_tenant_id: Annotated[Optional[str], Header()] = None,
    settings: Settings = Depends(get_settings),
) -> Principal:
    """
    Authenticate caller and derive tenant from the API key.

    X-Tenant-Id is never authority. If supplied and mismatched, reject.
    """
    raw_key = _extract_bearer(authorization)
    principal = resolve_principal(raw_key, settings)
    if x_tenant_id is not None and x_tenant_id != principal.tenant_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="X-Tenant-Id does not match authenticated tenant",
        )
    request.state.principal = principal
    return principal


def require_admin(
    request: Request,
    authorization: Annotated[Optional[str], Header()] = None,
    token: Annotated[Optional[str], Query()] = None,
    settings: Settings = Depends(get_settings),
) -> AdminPrincipal:
    """Admin auth via Authorization: Bearer only. Query-param tokens are rejected."""
    request_id = getattr(request.state, "request_id", None)

    def _deny(reason: str) -> None:
        try:
            write_admin_audit(
                actor="anonymous",
                action="admin_auth",
                outcome="denied",
                request_id=request_id,
                reason=reason,
            )
        except Exception:
            # Never block denial path on audit failure.
            pass
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if token:
        _deny("query_param_token_rejected")
    try:
        raw = _extract_bearer(authorization)
    except HTTPException:
        _deny("missing_or_invalid_authorization_header")
    if not hmac.compare_digest(raw, settings.admin_token):
        _deny("invalid_admin_token")
    return AdminPrincipal()
