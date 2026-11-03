# Phase 1 — Verified flaw inventory

**Date:** 2026-11-03  
**Environment:** local Docker Compose  
**Evidence transcript:** [`baseline-smoke.txt`](baseline-smoke.txt)  
**Seed counts:** [`seed-counts.txt`](seed-counts.txt)

## Runtime proofs

| ID | Flaw | Proof | Impact |
|----|------|-------|--------|
| F1 | No authentication; tenant from `X-Tenant-Id` | Setting `X-Tenant-Id: brightpath` lists Brightpath records with no credential | Any caller can impersonate any tenant |
| F2 | IDOR on `GET /records/{id}` | `GET /records/3` returned Brightpath payload `SKU-SECRET` with no tenant check | Cross-tenant read by guessing/enumerating IDs |
| F3 | SQL injection in `list_records` search | `search=' OR 1=1 --` as Acme returned **Acme + Brightpath + Cobalt** rows in one response | Full table disclosure across tenants |
| F4 | Admin unauthorized → HTTP 200 | `DELETE ...?token=wrong` → `200` + `{"error":"unauthorized"}` | Breaks clients/monitors; hides auth failures |
| F5 | Default admin token + query param | `token=letmein` deleted `throwaway` | Trivial privilege escalation |
| F6 | Admin token logged | API log: `deleted tenant throwaway using token letmein` | Secret leakage to log aggregators |
| F7 | Startup race vs Postgres | First API boot failed with connection refused before DB ready | Flaky local/prod boots (`depends_on` without health) |
| F8 | `/health` always ok | Returns `{"status":"ok"}` with no DB check | Orchestrators route traffic to broken app |

## Static / config flaws (confirmed by inspection + compose)

| ID | Flaw | Location |
|----|------|----------|
| F9 | Default `DATABASE_URL` / `ADMIN_TOKEN` in code | `app/main.py` |
| F10 | DB port published on host `0.0.0.0:5432` | `docker-compose.yml` |
| F11 | Cleartext DB password in compose | `docker-compose.yml` |
| F12 | Container runs as root | `app/Dockerfile` (no USER); build pip-as-root warning |
| F13 | Autocommit, no pool/timeouts | `get_conn()` |
| F14 | Heavy report artificial sleep + self-join | `/reports/heavy` |

## Baseline data loaded

| Tenant | Records |
|--------|---------|
| acme | 20001 (20000 seed + 1 smoke create) |
| brightpath | 2 (smoke only) |
| cobalt | 5000 |

## Local-only mitigation applied in Phase 1

- Added Postgres `healthcheck` + `depends_on: condition: service_healthy` + API `restart: on-failure` so baseline boots reliably. **Does not fix application security flaws.**
