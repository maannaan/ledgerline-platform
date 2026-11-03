"""Append-only admin audit trail. Never log secrets."""

from __future__ import annotations

import json
from typing import Any, Optional

from psycopg.types.json import Jsonb

from db import connection


def write_admin_audit(
    *,
    actor: str,
    action: str,
    outcome: str,
    target_tenant: Optional[str] = None,
    request_id: Optional[str] = None,
    reason: Optional[str] = None,
    detail: Optional[dict[str, Any]] = None,
) -> int:
    payload = detail or {}
    with connection() as conn:
        row = conn.execute(
            """
            INSERT INTO admin_audit_events
                (actor, action, target_tenant, request_id, outcome, reason, detail)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                actor,
                action,
                target_tenant,
                request_id,
                outcome,
                reason,
                Jsonb(payload),
            ),
        ).fetchone()
    return int(row[0])


def audit_to_public_dict(row: tuple) -> dict[str, Any]:
    return {
        "id": row[0],
        "created_at": row[1].isoformat() if row[1] else None,
        "actor": row[2],
        "action": row[3],
        "target_tenant": row[4],
        "request_id": row[5],
        "outcome": row[6],
        "reason": row[7],
        "detail": row[8] if not isinstance(row[8], str) else json.loads(row[8]),
    }
