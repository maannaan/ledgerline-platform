# Founder Briefing

**Audience:** Predixion founders / interview panel  
**Live session assumption:** Saturday 7 Nov 2026, 15:00 (confirm)

## One-minute story

Ledgerline must grow from one fragile shared VM to eight tenants with isolation, restore proof, and operable automation. We prioritize **security + reliability evidence**, then show **Reliability Autopilot** as a bounded detect→decide→act→verify loop.

## What exists today (Phase 4)

- Live Mumbai staging with **CI**, **digest deploys**, **one-step rollback**, tenant-aware **logs/metrics**.
- CloudWatch dashboard **Ledgerline-Staging** + 3 SLO-tied alarms → email.
- Canary = ship to Acme first; expand/contract DB migrations documented.
- Confirm SNS subscription email when prompted.

## What we will defend Saturday

1. Tenant isolation with automated negative tests  
2. IaC + one-step onboard (shared vs dedicated)  
3. Timed restore (Evergreen targets)  
4. Load + noisy-neighbour evidence  
5. Autopilot dry-run / kill switch / audit (differentiator)

## Honest limitations

See `assessment/KNOWN_LIMITATIONS.md` — updated as work proceeds.
