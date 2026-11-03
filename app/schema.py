"""Schema bootstrap for records, API keys, and admin audit."""

from __future__ import annotations

from db import connection


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS records (
    id SERIAL PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_records_tenant_id ON records (tenant_id);
CREATE INDEX IF NOT EXISTS idx_records_tenant_id_id ON records (tenant_id, id);

CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    key_hash TEXT NOT NULL UNIQUE,
    tenant_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('tenant_user', 'tenant_admin')),
    label TEXT NOT NULL DEFAULT '',
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant ON api_keys (tenant_id);

CREATE TABLE IF NOT EXISTS admin_audit_events (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    actor TEXT NOT NULL,
    action TEXT NOT NULL,
    target_tenant TEXT,
    request_id TEXT,
    outcome TEXT NOT NULL,
    reason TEXT,
    detail JSONB NOT NULL DEFAULT '{}'::jsonb
);
-- No UPDATE/DELETE grants are assumed for app role in production.
-- Locally we still avoid providing update helpers.
"""


def apply_schema() -> None:
    with connection(autocommit=True) as conn:
        conn.execute(SCHEMA_SQL)
