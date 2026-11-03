# Error Budget Policy (one page)

**SLO:** 99.9% availability → monthly error budget ≈ **0.1%** of eligible requests/time.

## Burn actions

| Budget consumed | Action |
|-----------------|--------|
| **&lt; 50%** | Normal feature delivery; review weekly reliability signals |
| **50–75%** | Reliability owner reviews top contributors; prefer reliability fixes in sprint |
| **75–100%** | Risky releases require reliability review + explicit rollback plan; increase page sensitivity |
| **≥ 100%** | **Freeze** non-essential feature releases. Allow security, compliance, and reliability fixes only, with owner approval |

## Exceptions

- Critical security patches always ship (even during freeze), with canary + rapid rollback.
- Customer-impacting incidents pause the freeze discussion until mitigated.

## Ownership

- **Error budget owner:** founding reliability engineer (interim)
- **Release freeze authority:** reliability owner + engineering lead
- **Review cadence:** weekly during assessment; biweekly thereafter

## Communication

When budget hits 75% or freeze: notify founders/customers of reliability focus and expected restoration timeline.
