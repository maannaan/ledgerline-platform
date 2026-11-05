# First bottleneck writeup (T5.4) — updated 2026-11-05

**Environment:** staging ALB / shared RDS `ll-staging-shared-pg` (t4g.micro) + Delta dedicated · ap-south-1  

## Observed

| Run | RPS target | Achieved approx | p95 `/records` | Error rate | Conclusion |
|-----|------------|-----------------|----------------|------------|------------|
| Smoke | 20 / 30s | ~20 | **134.7 ms** | 0% | OK under light load |
| Baseline #1 (pre-fix) | 200 / 10m | ~23 | **24.7 s** | 0% | Saturated |
| After scale to 2 tasks (no query fix) | 200 / 10m | ~18 | **60 s** | **41%** | Worse — same bug |
| Tuned baseline (LIMIT fix, 256CPU) | 200 / 10m | ~120 | **7.15 s** | 0% | Query fixed; capacity short |
| With Cobalt heavy (256CPU) | 200 / 10m | ~116 | **7.27 s** | 0.05% | Isolation OK |
| **Capacity retest 512CPU/1GB ×2** | 200 / 10m | **~200** | **131.6 ms** | **0%** | **SLO PASS** |

## Root cause chain

1. **First bottleneck:** `GET /records` ignored pagination and always ran `ILIKE '%%'` (~300KB responses). Fixed with `limit` + skip empty search.  
2. **Second bottleneck:** 0.25 vCPU / 0.5 GB task(s) could not sustain 200 RPS even after the query fix (~120 RPS, multi-second p95).  
3. **Fix validated:** bump to **512 CPU / 1024 MB × 2 tasks** → ~200 RPS, p95 **131.56 ms**, 0% errors (RDS class unchanged).

## Mitigations shipped

- Records `LIMIT` + skip empty ILIKE  
- Heavy-report concurrency cap + statement timeout  
- Documented capacity: lean idle (256/512 ×1); load/demo profile (512/1024 ×2)

## Evidence

- `docs/evidence/phase5/load-baseline*.txt`, `load-noisy.txt`  
- `docs/evidence/phase8/load-capacity.txt` + sanitized summary JSON  
