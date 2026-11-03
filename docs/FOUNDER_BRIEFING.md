# Founder Briefing

**Audience:** Predixion founders / interview panel  
**Live session assumption:** Saturday 7 Nov 2026, 15:00 (confirm)

## One-minute story

Ledgerline must grow from one fragile shared VM to eight tenants with isolation, restore proof, and operable automation. We prioritize **security + reliability evidence**, then show **Reliability Autopilot** as a bounded detect→decide→act→verify loop (optional after core).

## What exists today (through Phase 6)

- Live Mumbai staging: ECS/ALB/RDS/KMS/Secrets, **CI green**, digest deploy + one-step rollback  
- Tenant isolation with automated tests; shared + dedicated (Delta) tiers  
- Timed restore: **RTO 8.25m / RPO 6.23m** (Evergreen targets met on staging)  
- Load: unbounded `/records` found & fixed; ~120 RPS @ 0% errors; p95 still ~7s on lean size (honest gap)  
- Cobalt noisy: **no material cross-tenant harm**  
- Runbooks (onboard / restore / IR), blameless PIR, cost model, 90-day plan  

## What we will defend Saturday

1. Tenant isolation with automated negative tests  
2. IaC + one-step onboard (shared vs dedicated)  
3. Timed restore (Evergreen targets)  
4. Load + noisy-neighbour evidence + bottleneck honesty  
5. How we run the service (runbooks, cost, 90-day, first hire)  
6. Autopilot dry-run / kill switch / blocked restore (`make autopilot-demo`)

## Honest limitations

- Staging ALB HTTP until domain + ACM  
- p95 &lt; 300ms @ 200 RPS not met on current task/RDS size  
- See `assessment/KNOWN_LIMITATIONS.md`
