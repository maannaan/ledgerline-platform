# 90-Day Engineering Plan (≤2 pages)

**Context:** After assessment week — staging live in Mumbai; isolation, CI, restore, and load evidence exist. Gaps: p95&lt;300ms @ 200 RPS on lean size; TLS needs a domain; Autopilot still optional.

## Days 1–30 — Secure baseline & ownership

| Focus | Deliverables |
|-------|----------------|
| Understand & inventory | Threat model refresh; tenant inventory (shared vs dedicated); owner map |
| Operate | On-call rota stub; alarm → page path; practice one IR using `docs/runbooks/incident-response.md` |
| Prove recovery | Second timed restore (prod-class); record RTO/RPO |
| Release | Keep digest deploy + rollback; add list-limit regression test from PIR |
| SLOs | Publish staging SLO dashboard; error-budget policy already drafted — start weekly review |

**Exit criteria:** New engineer can onboard a shared tenant and roll back a bad deploy from runbooks alone.

## Days 31–60 — Scale onboarding & reduce toil

| Focus | Deliverables |
|-------|----------------|
| Automation | One-command dedicated onboard including key issuance workflow (no plaintext in tickets long-term) |
| Capacity | Model to hit p95&lt;300ms @ 200 RPS (workers / task size / RDS class); re-run k6; update cost model |
| Cost | Per-tenant attribution tags; monthly CE export vs `COST_MODEL.md` |
| Security | Secrets rotation drill; questionnaire pack complete for Delta-class; optional TLS with ACM |
| Load | Quarterly noisy-neighbour game; Cobalt-class tenant limits documented |

**Exit criteria:** Dedicated tenant onboard &lt; 30 minutes; cost variance explained monthly.

## Days 61–90 — Reliability maturity & team

| Focus | Deliverables |
|-------|----------------|
| Process | Error-budget burn alerts; blameless PIR habit |
| DR | Cross-AZ or snapshot restore game day; document Granite multi-region decision (still stretch) |
| Policy | CI policy-as-code (tfsec/Checkov); Autopilot dry-run in staging if core stable |
| People | Service ownership chart; hiring plan (below) |

**Exit criteria:** One game day completed with PIR; Autopilot either shipped bounded or explicitly deferred with rationale.

## First hire (from measured bottlenecks)

**Role:** Platform / SRE generalist (not “hire a title”).  
**Why now:** Load evidence shows capacity engineering + DB performance work ahead; restore/on-call surface grows with each dedicated tenant; toil on manual key/TLS/cost reviews.  
**Workload that justifies the hire:** (1) capacity & query performance to close SLO gap, (2) dedicated-tenant automation + DR game days, (3) on-call coverage so founders are not primary pages.  
**Timing:** Start search in days 45–60 if ≥2 dedicated customers are signed or SLO gap blocks sales.  
**Not first:** Separate security-only hire — fold into platform until questionnaire/compliance load exceeds one person.
