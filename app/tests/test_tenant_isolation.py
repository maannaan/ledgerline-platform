"""Negative tenant-isolation tests. Must pass in CI (Task 2 / Task 4)."""

from __future__ import annotations

import os
import uuid

import pytest
from fastapi.testclient import TestClient

# Ensure fail-closed settings exist before importing the app.
os.environ.setdefault(
    "DATABASE_URL",
    "postgresql://admin:admin123@127.0.0.1:5432/ledgerline",
)
os.environ.setdefault("ADMIN_TOKEN", "test-admin-token-phase2")
os.environ.setdefault("API_KEY_PEPPER", "test-pepper-phase2")

from auth import generate_api_key, hash_api_key  # noqa: E402
from config import load_settings  # noqa: E402
from db import connection, init_pool  # noqa: E402
from main import app  # noqa: E402
from schema import apply_schema  # noqa: E402


@pytest.fixture(scope="module")
def client():
    settings = load_settings()
    init_pool(settings)
    apply_schema()
    with TestClient(app) as c:
        yield c


@pytest.fixture
def tenants(client):
    """Provision two isolated tenants with unique keys for each test."""
    settings = load_settings()
    suffix = uuid.uuid4().hex[:8]
    tenant_a = f"tenant_a_{suffix}"
    tenant_b = f"tenant_b_{suffix}"
    key_a = generate_api_key()
    key_b = generate_api_key()

    with connection() as conn:
        for tenant, key in ((tenant_a, key_a), (tenant_b, key_b)):
            conn.execute(
                """
                INSERT INTO api_keys (key_hash, tenant_id, role, label)
                VALUES (%s, %s, 'tenant_user', %s)
                """,
                (hash_api_key(key, settings.api_key_pepper), tenant, f"test-{tenant}"),
            )
    return {
        "a": {"id": tenant_a, "key": key_a},
        "b": {"id": tenant_b, "key": key_b},
        "admin": os.environ["ADMIN_TOKEN"],
    }


def _auth(key: str, tenant_header: str | None = None) -> dict[str, str]:
    headers = {"Authorization": f"Bearer {key}"}
    if tenant_header is not None:
        headers["X-Tenant-Id"] = tenant_header
    return headers


def test_health_and_ready(client):
    assert client.get("/health").status_code == 200
    assert client.get("/ready").status_code == 200


def test_unauthenticated_rejected(client):
    assert client.get("/records").status_code == 401
    assert client.post("/records", json={"x": 1}).status_code == 401


def test_create_and_list_scoped(client, tenants):
    a, b = tenants["a"], tenants["b"]
    ra = client.post("/records", json={"sku": "A1"}, headers=_auth(a["key"]))
    rb = client.post("/records", json={"sku": "B1"}, headers=_auth(b["key"]))
    assert ra.status_code == 201
    assert rb.status_code == 201
    listed = client.get("/records", headers=_auth(a["key"])).json()
    skus = [row["payload"]["sku"] for row in listed]
    assert "A1" in skus
    assert "B1" not in skus


def test_cannot_get_other_tenant_record(client, tenants):
    a, b = tenants["a"], tenants["b"]
    created = client.post("/records", json={"sku": "SECRET"}, headers=_auth(b["key"])).json()
    resp = client.get(f"/records/{created['id']}", headers=_auth(a["key"]))
    assert resp.status_code == 404
    assert resp.json()["error"] == "not_found"


def test_header_spoof_rejected(client, tenants):
    a, b = tenants["a"], tenants["b"]
    client.post("/records", json={"sku": "B-ONLY"}, headers=_auth(b["key"]))
    resp = client.get("/records", headers=_auth(a["key"], tenant_header=b["id"]))
    assert resp.status_code == 403


def test_sqli_search_cannot_escape_tenant(client, tenants):
    a, b = tenants["a"], tenants["b"]
    client.post("/records", json={"sku": "A-OK"}, headers=_auth(a["key"]))
    client.post("/records", json={"sku": "B-LEAK"}, headers=_auth(b["key"]))
    resp = client.get(
        "/records",
        params={"search": "' OR 1=1 --"},
        headers=_auth(a["key"]),
    )
    assert resp.status_code == 200
    payloads = [row["payload"] for row in resp.json()]
    assert all("B-LEAK" not in str(p) for p in payloads)


def test_report_scoped(client, tenants):
    a, b = tenants["a"], tenants["b"]
    client.post("/records", json={"sku": "A"}, headers=_auth(a["key"]))
    client.post("/records", json={"sku": "B"}, headers=_auth(b["key"]))
    resp = client.get("/reports/heavy", headers=_auth(a["key"]))
    assert resp.status_code == 200
    assert resp.json()["tenant"] == a["id"]


def test_tenant_cannot_use_admin(client, tenants):
    resp = client.delete(
        f"/admin/tenants/{tenants['b']['id']}",
        headers=_auth(tenants["a"]["key"]),
    )
    assert resp.status_code == 401


def test_admin_query_param_rejected_and_audited(client, tenants):
    resp = client.delete(
        f"/admin/tenants/{tenants['a']['id']}",
        params={"token": tenants["admin"]},
    )
    assert resp.status_code == 401


def test_admin_delete_and_audit(client, tenants):
    a = tenants["a"]
    client.post("/records", json={"sku": "TO-DELETE"}, headers=_auth(a["key"]))
    resp = client.delete(
        f"/admin/tenants/{a['id']}",
        headers={"Authorization": f"Bearer {tenants['admin']}"},
    )
    assert resp.status_code == 200
    assert resp.json()["deleted"] == a["id"]
    listed = client.get("/records", headers=_auth(a["key"]))
    assert listed.status_code == 200
    assert listed.json() == []

    audit = client.get(
        "/admin/audit",
        headers={"Authorization": f"Bearer {tenants['admin']}"},
    )
    assert audit.status_code == 200
    actions = [e["action"] for e in audit.json()]
    assert "delete_tenant_records" in actions
    # Ensure raw admin token never appears in audit payload strings
    blob = str(audit.json())
    assert tenants["admin"] not in blob
