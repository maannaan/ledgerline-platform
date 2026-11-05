# Delta Finance — Security Questionnaire

**Status:** Answers reflect **staging cloud controls** verified 2026-11-03…2026-11-05 (ap-south-1), plus local isolation tests.  
**Audience:** Delta Finance security team  
**Honesty rule:** Labels below match evidence, not aspirational marketing.

## Answers

| # | Status | Answer |
|---|--------|--------|
| 1 | Implemented and tested | Tenant access uses Bearer API keys bound to one `tenant_id`. Server derives tenant from the key hash; `X-Tenant-Id` is never authority (mismatch → 403). SQL is parameterized and tenant-scoped. Automated isolation tests run in CI. **Delta has a dedicated RDS instance + dedicated KMS CMK** on staging (`ll-staging-delta-pg`, `alias/ll-staging-delta`). |
| 2 | Partial | **At rest:** RDS storage encryption with KMS (shared key for pooled DB; dedicated key for Delta) — cloud verified. **In transit:** staging ALB is currently **HTTP** (no customer domain/ACM yet). TLS enablement path documented (`docs/runbooks/enable-tls.md`). Local Compose remains HTTP by design. |
| 3 | Partial | App secrets (DB URL, admin token, pepper) live in **AWS Secrets Manager**; ECS task roles fetch them (no secrets in image). Admin API uses shared `ADMIN_TOKEN` Bearer with append-only `admin_audit_events`. Formal joiner/mover/leaver + SSO MFA is **not** productized (90-day plan). |
| 4 | Not currently supported | MFA / SSO for staff production access is not in this assessment build. Planned in days 31–60 with OIDC. |
| 5 | Partial | API keys stored as peppered SHA-256 hashes only. Pepper + admin token in Secrets Manager. Rotation without downtime is stretch / month-2 (S4 deferred). |
| 6 | Implemented but not independently certified | Structured JSON logs with `request_id` / `trace_id` / tenant; Prometheus `/metrics`; CloudWatch dashboard **Ledgerline-Staging** + alarms. Admin audit omits secrets. Customer log-export productization still planned. |
| 7 | Implemented and tested (staging drill) | RDS automated backups (7-day retention) enable PITR (`LatestRestorableTime`). Evergreen-class restore into a **new** instance measured: **RTO 8.25 min**, **RPO 6.23 min** (targets ≤60 / ≤15). Evidence: `docs/evidence/phase5/restore-drill-*.json`. Runbook: `docs/runbooks/database-restore.md`. |
| 8 | Implemented and tested | GitHub Actions CI: pytest isolation, `pip-audit`, Trivy image scan, `terraform validate`. Critical fix SLA remains organizational (on-call process in 90-day plan). |
| 9 | Implemented (process) | Peer-followable IR runbook (`docs/runbooks/incident-response.md`); blameless PIR from load incident (`docs/post-incident-review.md`). Customer notification timelines to be finalized with founders (proposed: prompt notice after containment for tenant-data incidents). |
| 10 | Partial | Primary region for this assessment: **`ap-south-1` (Mumbai)**. Multi-region (Granite) is stretch / deferred. Cloud subprocessors = AWS for staging. |
| 11 | Partial | Admin can delete a tenant’s records via audited API. Full contractual deletion attestation / legal hold workflow is not productized. |
| 12 | Not currently supported | No SOC 2 / ISO 27001 today. Controls above are chosen to support a future certification path. |

## Evidence pointers

- Isolation tests / SECURITY.md — Phase 2 + CI  
- Staging inventory — `docs/evidence/phase8/aws-inventory.txt`  
- Restore timing — `docs/evidence/phase5/`  
- Cost / 90-day — `docs/COST_MODEL.md`, `docs/90_DAY_PLAN.md`

## Status labels

- **Implemented and tested**
- **Implemented but not independently certified**
- **Partial**
- **Planned**
- **Not currently supported**
