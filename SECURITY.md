# SECURITY.md

Flaws found in the supplied reference application, verification evidence, and fix status.

## Phase 2 status (2026-11-03)

| Flaw | Fix | Evidence | Status |
|------|-----|----------|--------|
| Tenant from `X-Tenant-Id` / no auth | Bearer API key → server-derived tenant; mismatched header → 403 | `docs/evidence/phase2/` + pytest | **TESTED** |
| IDOR `GET /records/{id}` | `WHERE id=%s AND tenant_id=%s`; else 404 | live IDOR → 404 | **TESTED** |
| SQL injection in search | Parameterized `ILIKE %s` | pytest + live SQLi no cross-tenant leak | **TESTED** |
| Default DB/admin secrets in code | Fail-closed `config.py` (required env) | startup without env fails | **TESTED** |
| Admin token via query param | Rejected with 401; Bearer only | live + pytest | **TESTED** |
| Unauthorized admin HTTP 200 | Now 401 | live | **TESTED** |
| Admin token printed in app logs | Structured admin log without secret | no `using token` lines | **TESTED** |
| No admin audit trail | `admin_audit_events` append-only inserts | `/admin/audit` + pytest | **TESTED** |
| Health always ok | `/health` liveness + `/ready` DB check | curl ready | **TESTED** |
| Autocommit / no pool | `psycopg_pool` + statement timeout | code | **IMPLEMENTED** |
| Heavy report unscoped | Tenant from principal only | pytest | **TESTED** |
| Container runs as root | Non-root UID 10001 in Dockerfile | rebuild | **IMPLEMENTED** |
| DB port / compose creds (local) | Lab-only; Secrets Manager on staging | phase3 | **CLOUD_VERIFIED** (lab compose still weak by design) |
| TLS / encryption at rest | RDS+KMS at rest; ALB TLS gated on ACM domain | enable-tls.md | **PARTIAL** (rest done; transit HTTPS DEFERRED without domain) |
| Access log may include `?token=` if client sends it | Auth rejects it; uvicorn still logs URL | phase2 isolation-proof | **KNOWN residual** |

## Design summary

- **Authority:** `Authorization: Bearer <api_key>` maps to hashed row in `api_keys` → `tenant_id` + `role`.
- **`X-Tenant-Id`:** never grants access; mismatch is forbidden.
- **Admin:** `ADMIN_TOKEN` via Bearer only; `hmac.compare_digest`; audit on deny/success.
- **Keys:** SHA-256(`pepper:key`) stored; plaintext only at bootstrap stdout / local `.env` (gitignored).

## How to verify

```bash
docker compose up -d
docker compose exec api python bootstrap_auth.py
docker compose exec -e DATABASE_URL=postgresql://admin:admin123@db:5432/ledgerline \
  -e ADMIN_TOKEN -e API_KEY_PEPPER api python -m pytest
```
