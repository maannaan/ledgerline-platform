# Implementation Plan

## Sequence

| Phase | Focus | Exit gate |
|-------|-------|-----------|
| 0 | Init repo, extract PDF, persistent KB | Done when CURRENT_STATE says Phase 0 complete |
| 1 | Local baseline + flaw inventory | Compose runs; flaws listed |
| 2 | Security & isolation | Negative tests TESTED |
| 3 | Terraform platform + onboard | validate/plan; apply only if approved |
| 4 | CI/CD + observability | pipeline green; SLO/alerts documented |
| 5 | Backup/restore + load + noisy neighbour | measured evidence saved |
| 6 | Runbooks, PIR, cost, 90-day, README | reviewer-operable |
| 7 | Reliability Autopilot wow track | dry-run + kill switch demo |
| 8 | Founder rehearsal | DEMO_RUNBOOK practiced |

## Priority rule

Security (20%) + Reliability evidence (30%) before Autopilot polish.

## Cloud gate

No `terraform apply` until: billing alarms set, region confirmed, user approves estimate.
