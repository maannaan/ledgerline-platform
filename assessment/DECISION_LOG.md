# Decision Log

| Date | Decision | Rationale | Alternatives considered | Status |
|------|----------|-----------|-------------------------|--------|
| 2026-11-03 | AWS as cloud provider | Candidate experience; playbook proposal; PDF allows any | GCP/Azure | ACCEPTED |
| 2026-11-03 | Keep FastAPI reference stack | Endpoint compatibility; time; explainability | Rewrite in another language | ACCEPTED |
| 2026-11-03 | Git root = `ledgerline-platform` only | Home directory had accidental git; avoid nested/wrong commits | Using parent git | ACCEPTED |
| 2026-11-03 | Compose at repo root with `build: ./app` | Matches PDF repo layout (`app/`) while keeping Dockerfile next to code | Compose inside `app/` | ACCEPTED |
| 2026-11-03 | Source PDF/HTML under `assessment/source/` | Preserve assets; clear SoT path | Leave only at repo root | ACCEPTED |
| 2026-11-03 | 3–4 day cloud window; target $25–40 / soft $75 | User has ~$170 credits; assessment does not reward spend | Full-week dual env | ACCEPTED |
| 2026-11-03 | Reliability Autopilot as differentiator after core gate | Founder wow without displacing scored core | Skip Autopilot; LLM remediator | ACCEPTED |
| 2026-11-03 | Granite multi-region / Fjord 10x = DEFERRED stretch | Depth over breadth; timebox | Implement early | ACCEPTED |
| 2026-11-03 | Compose DB healthcheck + API wait/restart | Baseline API crashed on first boot (DB not ready); needed reproducible Phase 1 | App-level retry only | ACCEPTED |
| 2026-11-03 | Seed Acme 20k + Cobalt 5k locally in Phase 1 | Matches PDF seed guidance; enables later heavy-report tests | Defer cobalt seed | ACCEPTED |
| 2026-11-03 | API keys hashed with peppered SHA-256 | Simple, explainable for assessment; keys revocable in DB | bcrypt/argon2; JWT/OIDC | ACCEPTED |
| 2026-11-03 | Reject mismatched `X-Tenant-Id` with 403 | Makes spoof attempts explicit; header never authority | Ignore header silently | ACCEPTED |
| 2026-11-03 | Admin auth = shared `ADMIN_TOKEN` Bearer | Matches assessment admin surface; audited | Per-admin OIDC (later) | ACCEPTED |
| 2026-11-03 | Keep heavy self-join for Cobalt tests | Needed for Task 5 noisy-neighbour; now tenant-scoped | Replace with cheap count | ACCEPTED |
| 2026-11-03 | No NAT; Fargate public IP | Cut 3–4 day cost; DB still private via SG | NAT + private subnets | ACCEPTED |
| 2026-11-03 | Dedicated RDS+KMS per dedicated tenant (Delta) | Matches Delta requirements literally | Schema-only “dedicated” | ACCEPTED |
| 2026-11-03 | `APPROVE_APPLY=1` Makefile guard | Prevent accidental billable apply | Rely on human memory | ACCEPTED |
| 2026-11-03 | Primary region `ap-south-1` (Mumbai) | User request; AWS CLI already on Mumbai | us-east-1 | ACCEPTED |
| 2026-11-03 | Apply staging only first (not prod) | Stay near $25–40 burn; prod code ready | Dual-env apply | ACCEPTED |
| 2026-11-03 | Local Acme COPY rehearsal + written CDC cutover | Prove seed move; honest about prod replication | Claim zero-downtime CDC implemented | ACCEPTED |
