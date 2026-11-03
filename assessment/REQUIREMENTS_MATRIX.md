# Requirements Matrix

Statuses: `NOT_STARTED | IN_PROGRESS | IMPLEMENTED | TESTED | CLOUD_VERIFIED | BLOCKED | DEFERRED`  
Never mark TESTED/CLOUD_VERIFIED without evidence paths.

## Task 1 — Platform as code

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T1.1 | IaC from empty cloud account | `infra/` | `terraform validate/plan/apply` | apply log + outputs phase3 | CLOUD_VERIFIED |
| T1.2 | Staging + prod same code | `infra/environments/*` | compare modules | both validate; staging applied | IMPLEMENTED |
| T1.3 | Repeatable shared/dedicated onboard | `make onboard`, `infra/scripts/` | onboard cmds | tenant-list + SSM | CLOUD_VERIFIED |
| T1.4 | Demo ≥3 tenants (Acme, Brightpath shared; Delta dedicated) | manifests + registry module | `make tenant-list` | terraform outputs inventory | CLOUD_VERIFIED |
| T1.5 | Acme seed migration + &lt;5 min downtime plan | `migrate-acme-local`, cutover doc | count verify | phase3 acme migration evidence | TESTED |

## Task 2 — Security & separation

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T2.1 | Find/fix reference flaws; SECURITY.md | `app/*`, `SECURITY.md` | review + tests | phase1+phase2 evidence | TESTED |
| T2.2 | Real auth; no header-as-auth | `app/auth.py`, `main.py` | spoof header fails | `docs/evidence/phase2/` | TESTED |
| T2.3 | Automated tenant isolation tests in CI | `app/tests/test_tenant_isolation.py` | pytest (CI wire Phase 4) | `docs/evidence/phase2/pytest-isolation.txt` | TESTED |
| T2.4 | Secrets manager + least privilege | Secrets Manager + ECS task roles | staging live | phase3 evidence | CLOUD_VERIFIED |
| T2.5 | Encrypt transit/rest; admin audit immutable | RDS+KMS at rest; audit table; TLS optional ACM | audit pytest; TLS needs domain | enable-tls.md | IMPLEMENTED (TLS DEFERRED without domain) |
| T2.6 | Delta questionnaire honest | `docs/security-questionnaire.md` | review | partial answers | IN_PROGRESS |

## Task 3 — Observability

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T3.1 | Tenant-aware metrics/logs/traces | `app/telemetry.py`, middleware | `/metrics` + JSON logs | phase4 evidence | CLOUD_VERIFIED |
| T3.2 | Filterable dashboard | `observability/dashboards/` | CW dashboard | Ledgerline-Staging | CLOUD_VERIFIED |
| T3.3 | Availability + latency SLOs + rationale | `observability/slo/slos.md` | doc review | | IMPLEMENTED |
| T3.4 | ≥3 SLO-tied alerts | CW alarms + SNS | describe-alarms | phase4/alarms.txt | CLOUD_VERIFIED |
| T3.5 | One-page error budget policy | `observability/error-budget-policy.md` | doc | | IMPLEMENTED |

## Task 4 — Safe delivery

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T4.1 | CI: tests + dep/container scan + isolation | `.github/workflows/ci.yml` | local pytest + pip-audit; GHA after your push | phase4/*; GITHUB_FIRST_PUSH.md | IMPLEMENTED (CLOUD_VERIFIED after Actions green) |
| T4.2 | Zero-downtime deploy + one-step rollback | `deploy_staging.sh` / `rollback_staging.sh` | digest deploy | phase4/deploy-staging.txt | CLOUD_VERIFIED |
| T4.3 | Safe schema changes while serving | `docs/decisions/safe-migrations.md` | doc | | IMPLEMENTED |
| T4.4 | Canary one tenant then rest | `docs/runbooks/canary-rollout.md` | procedure | | IMPLEMENTED |

## Task 5 — Pressure & recovery

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T5.1 | Automated backups + Evergreen restore timed | backup/restore runbook | RTO/RPO measured | | NOT_STARTED |
| T5.2 | k6 200 RPS / 10m / 3 tenants; p95 &lt;300ms | `loadtest/` | k6 summary | | NOT_STARTED |
| T5.3 | Cobalt noisy neighbour; others in target | load + throttle | before/after | | NOT_STARTED |
| T5.4 | First bottleneck writeup | docs/evidence | writeup | | NOT_STARTED |

## Task 6 — Operations

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| T6.1 | 3 runbooks (onboard, restore, IR) | `docs/runbooks/` | peer can follow | | NOT_STARTED |
| T6.2 | Blameless PIR | `docs/post-incident-review.md` | doc | | NOT_STARTED |
| T6.3 | Cost model shared + dedicated | `docs/COST_MODEL.md` | calc | | NOT_STARTED |
| T6.4 | ≤2 page 90-day plan | `docs/90_DAY_PLAN.md` | doc | | NOT_STARTED |

## Stretch (after core)

| ID | Requirement | Status |
|----|-------------|--------|
| S1 | Granite second region | DEFERRED |
| S2 | Per-tenant cost attribution | DEFERRED |
| S3 | Policy as code in CI | DEFERRED |
| S4 | Secret rotation no downtime | DEFERRED |
| S5 | Fjord 10x autoscaling proof | DEFERRED |

## Differentiator (not PDF-scored)

| ID | Requirement | Implementation | Verification | Evidence | Status |
|----|-------------|----------------|--------------|----------|--------|
| D1 | Reliability Autopilot policies + dry-run + kill switch + audit | `autopilot/` | demo script | | NOT_STARTED |
| D2 | Ops control-plane Make targets | `Makefile` | demo | | NOT_STARTED |
