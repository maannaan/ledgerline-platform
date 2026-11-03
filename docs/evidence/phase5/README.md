# Phase 5 evidence

| Artifact | Requirement | Status |
|----------|-------------|--------|
| `restore-drill-20261103T100335Z.json` | T5.1 | PASS RTO 8.25m / RPO 6.23m |
| `load-smoke.txt` | prelude | PASS p95 134.7ms @ 20 RPS |
| `load-baseline.txt` | T5.2 pre-fix | FAIL p95 24.7s (unbounded list) |
| `load-baseline-tuned.txt` | T5.2 post-fix | ~120 RPS; p95 7.15s (SLO still miss) |
| `load-noisy.txt` | T5.3 | isolation OK (p95 7.27s) |
| `bottleneck-writeup.md` | T5.4 | complete |
