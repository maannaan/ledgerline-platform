# Source of Truth

## Priority order

1. **PDF (authoritative):** [`source/Founding Engineer 1-Week Live Assessment.pdf`](source/Founding%20Engineer%201-Week%20Live%20Assessment.pdf)
2. **Playbook (implementation guide):** [`source/ledgerline_assessment_cursor_playbook.html`](source/ledgerline_assessment_cursor_playbook.html)
3. **This repository** (actual implementation + evidence)
4. **Explicit user instructions** (enhancements allowed; must not silently override PDF)

## Assessment facts (from PDF)

- Role: Founding Reliability Engineer, 1-week live assessment (~20–25 hours).
- Nobody finishes everything; priorities and omissions are evaluated.
- Live session ~2 hours: walkthrough, incident drill, deep dive, 90-day plan.
- Cloud: candidate account; billing alert; spend under `[spend cap]` (placeholder in PDF); reimbursement placeholder.
- AI assistants allowed if disclosed in README and work can be explained/changed live.

## Six core tasks (IDs T1–T6)

See [`REQUIREMENTS_MATRIX.md`](REQUIREMENTS_MATRIX.md) for full traceability.

| ID | Task | Weight-relevant themes |
|----|------|------------------------|
| T1 | Platform as code | Automation 15% |
| T2 | Security & client separation | Security 20% |
| T3 | Observability | Reliability 30% |
| T4 | Safe delivery | Hands-on 10% |
| T5 | Pressure & recovery | Reliability 30% |
| T6 | Operations & leadership | Reliability function 10% + ownership/comms |

## Critical non-negotiable quotes (PDF)

- Do not trust `X-Tenant-Id` alone; replace with real authentication.
- Acme migration: no data loss, under 5 minutes downtime (describe + show on seed).
- Evergreen: restore within 1 hour, under 15 minutes data lost.
- Load: 200 RPS for 10 minutes across 3 tenants; p95 `/records` under 300 ms.
- Deploy without downtime; one-step rollback; canary one tenant first.

## Tenants

| Tenant | Tier | Notes |
|--------|------|-------|
| Acme Retail | shared | Live; migrate |
| Brightpath Learning | shared | Month 1 |
| Cobalt Logistics | shared | Heavy reports / noisy neighbour |
| Delta Finance | dedicated | Own DB, own key, audit, questionnaire |
| Evergreen Health | dedicated | RTO 1h / RPO 15m |
| Fjord Media | shared | 10x spikes (stretch) |
| Granite Insurance | dedicated | Other region (stretch) |
| Harbor Foods | shared | Month 6 |

## Starter artifacts (extracted Phase 0)

| Artifact | Path |
|----------|------|
| Reference API | `app/main.py` |
| Deps | `app/requirements.txt` |
| Container | `app/Dockerfile` |
| Compose | `docker-compose.yml` (build context `./app`) |
| Seed | `app/seed.py` |
| Load test | `loadtest/load.js` |
| Questionnaire stub | `docs/security-questionnaire.md` |

## Known PDF vs playbook notes

- PDF filenames placeholders for dates/spend; playbook assumes Thursday submit / Sat 7 Nov 15:00 — confirm with company.
- Playbook proposes AWS; PDF allows any cloud — AWS chosen by candidate decision (see DECISION_LOG).
- Reliability Autopilot is playbook/candidate differentiator, **not** a PDF core task.
