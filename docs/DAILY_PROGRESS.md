# Daily Progress

## 2026-11-03 — Phase 0

- Initialized project-local git repository (not home directory).
- Extracted PDF starter into `app/`, `docker-compose.yml`, `loadtest/load.js`.
- Created AGENTS.md, Cursor rules, assessment KB, founder doc skeletons.
- Built requirements matrix (all core items NOT_STARTED except questionnaire skeleton IN_PROGRESS).
- Moved PDF + playbook to `assessment/source/`.
- No application behavior changes beyond extraction/layout for `app/` build context.
- No cloud provisioning.

**Next:** Phase 1 — local baseline + flaw inventory (awaiting approval).

## 2026-11-03 — Phase 1

- Brought up Docker Compose (API + Postgres 16); fixed boot race with DB healthcheck.
- Verified `/health` and create/list `/records`.
- Seeded Acme 20,000 (+1 smoke) and Cobalt 5,000.
- Captured live proofs: header spoof, IDOR GET, SQL injection cross-tenant dump, admin 200-on-deny, token log leak.
- Evidence: `docs/evidence/phase1/`; `SECURITY.md` updated.
- No auth fixes yet (Phase 2).

**Next:** Phase 2 — security & tenant isolation (awaiting approval).

## 2026-11-03 — Phase 2

- Implemented fail-closed config, API-key auth, server-derived tenant, parameterized SQL.
- Admin Bearer-only + append-only audit; `/ready` checks DB.
- **10/10** isolation tests passed; live IDOR/spoof/SQLi/admin proofs saved under `docs/evidence/phase2/`.
- Residual: access log may echo `?token=` if client sends it; TLS/Secrets Manager deferred to cloud.

**Next:** Phase 3 — Terraform / platform as code (plan only until spend approved).

## 2026-11-03 — Phase 3

- Authored Terraform modules + staging/production roots; `terraform validate` Success both.
- Onboard path for shared/dedicated; inventory shows Acme/Brightpath shared, Delta dedicated.
- Local Acme migration 20002 rows matched; cutover runbook written.
- **No AWS apply** — blocked without `APPROVE_APPLY=1` + your spend approval.

**Next:** Approve staging apply (with budget email) **or** start Phase 4 CI/observability.

## 2026-11-03 — Budget email recorded

- Set staging budget alert to `mananpaliwal30@gmail.com` ($75 monthly limit) in gitignored `terraform.tfvars`.
- Still waiting for explicit “Approve staging apply” before any AWS resources.

## 2026-11-03 — Staging provisioned in Mumbai (ap-south-1)

- Applied staging stack; fixed Postgres version to **16.15** (16.4 unavailable in region).
- ALB healthy; ECR image pushed; API keys bootstrapped; cloud spoof test → 403.
- Prod not applied (cost). HTTP only (no ACM yet).

## 2026-11-03 — Phase 4

- CI workflow: isolation tests + pip-audit + Trivy + terraform validate.
- JSON logs + Prometheus `/metrics`; CloudWatch dashboard + 3 alarms + SNS email.
- Digest-pinned deploy + one-step rollback scripts; canary + expand/contract docs.
- 10/10 tests still passing; staging redeployed with observability build.

## 2026-11-03 — Phase 5

- Evergreen-class restore drill: RTO 8.25m / RPO 6.23m; temp RDS deleted.
- Load smoke OK; full 200 RPS exposed unbounded `/records` (~300KB) — fixed with LIMIT.
- Tuned baseline ~120 RPS / p95 ~7.15s; Cobalt noisy isolation OK (p95 ~7.27s).
- Bottleneck writeup + evidence under `docs/evidence/phase5/`.

## 2026-11-03 — Phase 6

- Completed peer-followable runbooks: onboard, restore, incident response.
- Blameless PIR from load/list incident; cost model; ≤2-page 90-day plan + first hire.
- Founder briefing refreshed through Phase 6.

## 2026-11-03 — Phase 7

- Built Reliability Autopilot: JSON policies, allowlisted actions, dry-run CLI, kill switch, audit JSONL.
- Demo script + Make targets; 4/4 unit tests passed; evidence in `docs/evidence/phase7/`.
- Restore remains human-gated; live cloud actions require APPROVE_AUTOPILOT=1.
