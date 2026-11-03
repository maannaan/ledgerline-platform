# Post-Incident Review (blameless)

**Incident:** Staging load baseline — unbounded `/records` list collapsed latency  
**Date of incident:** 2026-11-03  
**PIR date:** 2026-11-03  
**Severity:** Sev-2 (staging assessment environment; no production customer impact)  
**Incident lead:** Platform candidate (assessment)

## Summary

A k6 baseline targeting **200 RPS** against staging caused `/records` p95 to rise to **~25s** (later worse under scale-out). Root cause was application behavior: list endpoint returned **all** tenant rows with an always-on `ILIKE '%%'`, producing ~**300KB** responses. After adding `LIMIT` and skipping empty-search ILIKE, sustained throughput rose to ~**120 RPS** with **0%** errors; p95 remained ~**7s** on the lean Fargate/RDS size (SLO 300ms still missed — capacity gap, separately tracked).

## Customer impact

- **Production customers:** none (staging only).  
- **Assessment / demo risk:** false conclusion that “platform cannot meet load SLO” without distinguishing **bug** vs **capacity**.  
- Cobalt noisy-neighbour run after the fix showed **no material cross-tenant regression** (p95 7.15s → 7.27s).

## Detection

- k6 thresholds failed (`p(95)<300`).  
- Manual single-request check: `/records?limit=10` still returned ~300KB → confirmed ignored limit / full scan.  
- RDS CPU was **not** pegged (~5%) during cool-down — pointed away from “DB too small” as the *first* cause.

## Timeline (UTC, approx.)

| Time | Event |
|------|--------|
| 10:14 | Deployed heavy-report concurrency limits for noisy prep |
| 10:17 | Baseline #1 @ 200 RPS — p95 ~24.7s, ~23 RPS achieved |
| 10:28 | Scaled ECS to 2 tasks (hypothesis: API CPU) — errors rose to ~41% |
| 10:48 | Canary still poor; single-request proved ~300KB lists |
| ~11:00 | Shipped LIMIT + skip empty ILIKE; redeployed |
| 11:01–11:21 | Tuned baseline + noisy runs; isolation OK; p95 ~7s |

## Root cause

**Primary:** `GET /records` had no SQL `LIMIT` and always applied `payload::text ILIKE`, so empty search matched every row.

**Not the root cause:** RDS CPU saturation; Cobalt noisy neighbour (post-fix comparison).

## Contributing factors

- Load script initially exercised search-heavy paths; empty ILIKE still dominated once search rate dropped.  
- Scaling *out* without fixing payload size increased waiters on the same expensive query.  
- Missing automated assertion that list responses stay bounded (bytes / row count).

## What went well

- Honest measurement kept; no fabricated green SLO.  
- Evidence saved under `docs/evidence/phase5/`.  
- Isolation story separated from capacity story.  
- Restore drill earlier the same day met Evergreen RTO/RPO targets.

## What did not go well

- First mitigation (scale to 2) before confirming response size wasted time and spend.  
- List pagination was not covered by an explicit size/limit regression test before load day.

## Actions

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| Ship `/records` `limit` + skip empty ILIKE | Platform | 2026-11-03 | Done |
| Document bottleneck + evidence | Platform | 2026-11-03 | Done |
| Add pytest: list respects limit / small payload | Platform | Days 1–30 | Open |
| Capacity plan for p95&lt;300ms @ 200 RPS (CPU/workers/RDS) | Platform | Days 31–60 | Open |
| Optional response-size metric/alert | Platform | Days 31–60 | Open |

## Prevention / verification

- Re-run `make load-smoke` after list changes; fail if p95 &gt; 300ms at 20 RPS.  
- Contract test: `GET /records?limit=10` returns ≤10 rows.  
- Treat “scale first” as anti-pattern until payload/query cost is checked.
