# First bottleneck writeup (T5.4)

**Environment:** staging ALB / shared RDS `ll-staging-shared-pg` (t4g.micro) + Delta dedicated · ap-south-1  
**Date:** 2026-11-03

## Observed

| Run | RPS target | Achieved approx | p95 `/records` | Error rate | Conclusion |
|-----|------------|-----------------|----------------|------------|------------|
| Smoke | 20 / 30s | ~20 | **134.7 ms** | 0% | OK under light load |
| Baseline #1 (pre-fix) | 200 / 10m | ~23 | **24.7 s** | 0% | Saturated |
| After scale to 2 tasks (no query fix) | 200 / 10m | ~18 | **60 s** | **41%** | Worse — more waiters on same bug |
| Tuned baseline (LIMIT fix + pool 20 + 2 tasks) | 200 / 10m | ~120 | **7.15 s** | 0% | Fixed unbounded list; still above SLO |
| With Cobalt heavy | 200 / 10m | ~116 | **7.27 s** | 0.05% | Isolation OK |

## Root cause (first bottleneck)

`GET /records` ignored pagination and always ran `payload::text ILIKE` — empty search used `%%` and returned **entire tenant history** (~300KB for Acme). Under load this caused:
- huge JSON encode/transfer cost
- connection hold time → pool exhaustion → multi-second queues

## Fix shipped

- `limit` query param (default 50, max 200)
- Skip ILIKE when `search` is empty (indexed `tenant_id` + `ORDER BY id DESC LIMIT`)
- Heavy-report concurrency cap + statement timeout (noisy-neighbour)

## Remaining gap to p95&lt;300ms @ 200 RPS

Not noisy-neighbour. Next levers (not applied — cost): larger task CPU, more uvicorn workers, bigger RDS class, or read replica for search.

## Evidence paths

- `load-baseline.txt` / `load-baseline-tuned.txt` / `load-noisy.txt`
- `restore-drill-*.json` (RTO/RPO)
