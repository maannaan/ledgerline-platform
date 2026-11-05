# Founder Briefing

**Audience:** Predixion founders / interview panel  
**Live session assumption:** Saturday 7 Nov 2026, 15:00 (confirm)

## One-minute story

Ledgerline must grow from one fragile shared VM to eight tenants with isolation, restore proof, and operable automation. We prioritize **security + reliability evidence**, then show **Reliability Autopilot** as a bounded detect→decide→act→verify loop.

## What exists today (through Phase 7 + polish)

- Live Mumbai staging: ECS/ALB/RDS/KMS/Secrets, **CI green**, digest deploy + one-step rollback  
- Tenant isolation with automated tests; shared + dedicated (Delta) tiers  
- Timed restore: **RTO 8.25m / RPO 6.23m** (Evergreen targets met on staging)  
- Load: unbounded `/records` fixed; **capacity profile 512/1024×2 hits p95 131ms @ 200 RPS** (lean idle sized down for cost)  
- Cobalt noisy: **no material cross-tenant harm**  
- Runbooks, blameless PIR, cost model, 90-day plan, **Delta questionnaire** updated to staging reality  
- Autopilot: dry-run, kill switch, audit, restore blocked without human approval  

## What we will defend Saturday

1. Tenant isolation with automated negative tests  
2. IaC + one-step onboard (shared vs dedicated)  
3. Timed restore (Evergreen targets)  
4. Load + noisy-neighbour evidence + bottleneck honesty  
5. How we run the service (runbooks, cost, 90-day, first hire)  
6. Autopilot dry-run / kill switch / blocked restore (`make autopilot-demo`)  
7. Honest Delta questionnaire (TLS/MFA/SOC gaps called out)

## Honest limitations

- Staging ALB HTTP until domain + ACM  
- Lean idle size misses 200 RPS SLO; use documented demo capacity profile for proof (see phase8 evidence)  
- See `assessment/KNOWN_LIMITATIONS.md`
