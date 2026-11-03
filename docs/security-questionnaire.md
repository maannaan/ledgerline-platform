# Delta Finance — Security Questionnaire

**Status:** Partial answers reflecting **local Phase 2** implementation. Cloud controls not yet deployed.  
**Audience:** Delta Finance security team  

## Answers

| # | Status | Answer |
|---|--------|--------|
| 1 | Implemented and tested (app-layer) | Tenant data access is authorized via API keys bound to a single `tenant_id`. The server derives tenant identity from the credential; `X-Tenant-Id` is not authoritative. Queries are parameterized and scoped by tenant. Automated negative tests prove cross-tenant read/list/search/report/admin boundaries. **Dedicated database + KMS key for Delta is planned in infrastructure (not yet cloud-verified).** |
| 2 | Planned / partial | In transit: TLS terminated at load balancer planned for cloud deploy (local lab is HTTP). At rest: RDS encryption planned; Delta will receive a dedicated KMS customer-managed key. Local lab Postgres is not production encryption. |
| 3 | Planned | Production data access will be least-privilege IAM + break-glass admin token with audit. Today: local admin bearer token; every admin auth denial and delete is written to `admin_audit_events`. Formal joiner/mover/leaver review process is in the 90-day plan. |
| 4 | Not currently supported | MFA for staff production access is not implemented in this assessment build. Planned for month 2 with SSO/OIDC. |
| 5 | Partial | API keys stored as peppered SHA-256 hashes; admin token and pepper via environment (Secrets Manager planned). Rotation without downtime is a stretch goal / month 2. |
| 6 | Partial | Request IDs on responses; admin actions audited (actor, action, target tenant, outcome, request id) without secrets in audit payload. Log retention policy and customer export path planned with cloud observability. |
| 7 | Not currently supported | Automated backups + timed Evergreen restore are Task 5 — not yet executed. Targets: restore ≤1 hour, ≤15 minutes data loss. |
| 8 | Partial | Dependency/container scanning planned in CI (Task 4). Isolation tests exist locally. Critical fix SLA to be stated in runbooks once on-call exists. |
| 9 | Planned | Incident response runbook skeleton exists; customer notification timeline will be finalized with founders (proposed: security incidents affecting tenant data notified promptly after containment assessment). |
| 10 | Planned | Primary region planned `us-east-1`. Granite multi-region is stretch. Subprocessors (cloud provider) will be listed at deploy time. |
| 11 | Planned | Tenant record delete exists for admin; full contractual deletion attestation workflow not yet productized. |
| 12 | Not currently supported | No SOC 2 / ISO 27001 today. Building controls that support a future certification path. |

## Status labels

- **Implemented and tested**
- **Implemented but not independently certified**
- **Planned**
- **Not currently supported**
