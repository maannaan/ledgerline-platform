# Ledgerline Platform

Predixion AI — **Founding Reliability Engineer** live assessment.

Secure, multi-tenant B2B SaaS control plane: FastAPI + Postgres on AWS (`ap-south-1`), with shared and dedicated tenant tiers, CI, observability, timed restore, load evidence, runbooks, and a deterministic **Reliability Autopilot**.

| Doc | Purpose |
|-----|---------|
| [`assessment/CURRENT_STATE.md`](assessment/CURRENT_STATE.md) | Live handoff / what is running |
| [`assessment/REQUIREMENTS_MATRIX.md`](assessment/REQUIREMENTS_MATRIX.md) | Requirement IDs → status + evidence |
| [`docs/FOUNDER_BRIEFING.md`](docs/FOUNDER_BRIEFING.md) | Interview one-pager |
| [`docs/DEMO_RUNBOOK.md`](docs/DEMO_RUNBOOK.md) | Demo commands |
| [`docs/security-questionnaire.md`](docs/security-questionnaire.md) | Delta Finance answers |
| [`AGENTS.md`](AGENTS.md) | How agents work this repo |

---

## Architecture

```text
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │  ALB (HTTP*)    │  *TLS when ACM domain set
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │ ECS Fargate API │  FastAPI · digest-pinned image
              │ (public IP, no NAT — cost lean)
              └────────┬────────┘
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
  Secrets Manager   CloudWatch    ECR
  (DB/admin/pepper) logs/metrics  images
         │
    ┌────┴────────────────────┐
    ▼                         ▼
 Shared RDS              Dedicated RDS
 (Acme, Brightpath, …)   (Delta + KMS CMK)
 Postgres 16 · encrypted · private SG
```

**Tenant model**

| Tier | Tenants (demo) | Isolation |
|------|----------------|-----------|
| Shared | Acme, Brightpath, Cobalt, Harbor | App-layer `tenant_id` + API keys |
| Dedicated | Delta | Own RDS + own KMS key + audit |

**Auth logic:** `Authorization: Bearer <api_key>` → peppered SHA-256 lookup → server-derived `tenant_id`. `X-Tenant-Id` never grants access (mismatch → 403).

---

## Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| API | FastAPI / Python 3.12 | Assessment reference stack; fast to secure |
| DB | Postgres 16 on RDS `db.t4g.micro` | Managed backups/PITR; KMS encryption |
| Compute | ECS Fargate | No SSH pets; rolling deploy + circuit breaker |
| Edge | ALB | Health checks on `/ready` |
| Secrets | AWS Secrets Manager | No secrets in image/git |
| Crypto | KMS CMKs | Shared + per-dedicated-tenant |
| CI | GitHub Actions | pytest, pip-audit, Trivy, `terraform validate` |
| IaC | Terraform (staging applied; prod same modules, not applied) | Repeatable; cost-gated apply |
| Load | k6 | Assessment script + Make targets |
| Autopilot | Local deterministic CLI | Allowlist + dry-run + kill switch (no LLM exec) |

**Lean networking:** no NAT Gateway; tasks use public IP; RDS stays private via security groups.

---

## Approach (how we worked)

1. **Depth over breadth** — security + reliability evidence before stretch (multi-region, Autopilot after core).  
2. **Never trust headers** — fix reference auth flaws first; automated isolation tests in CI.  
3. **Staging-only cloud** — prod Terraform validated but not applied (budget).  
4. **Honest SLOs** — measure, fix root cause, re-measure; document capacity profiles.  
5. **Gates** — `APPROVE_APPLY=1`, `APPROVE_RESTORE=1`, `APPROVE_AUTOPILOT=1` before billable/risky actions.

---

## Application logic (high level)

| Route | Behavior |
|-------|----------|
| `POST/GET /records` | Tenant-scoped CRUD; list uses `LIMIT` (default 50); ILIKE search only when `search` set |
| `GET /records/{id}` | IDOR-safe: `id` **and** `tenant_id` |
| `GET /reports/heavy` | Expensive self-join for noisy-neighbour drills; concurrency cap + short `statement_timeout` |
| `/health` | Liveness |
| `/ready` | DB ping |
| `/metrics` | Prometheus (bounded tenant/endpoint labels) |
| `/admin/...` | Admin Bearer + append-only audit events |

---

## Benchmarks & evidence (staging)

| Test | Config | Result | Evidence |
|------|--------|--------|----------|
| Isolation | pytest in CI | Green | GHA + `docs/evidence/phase2/` |
| Restore (Evergreen-class) | Snapshot → new RDS | **RTO 8.25 min** · **RPO 6.23 min** | `docs/evidence/phase5/restore-drill-*.json` |
| Load smoke | 20 RPS / 30s | p95 ~135 ms | `docs/evidence/phase5/load-smoke.txt` |
| Load (lean 256CPU) | 200 RPS / 10m | ~120 RPS · p95 ~7s (capacity short) | `docs/evidence/phase5/load-baseline-tuned.txt` |
| Noisy (Cobalt) | + heavy VUs | p95 ~7.27s vs 7.15s — isolation OK | `docs/evidence/phase5/load-noisy.txt` |
| **Capacity profile** | **512 CPU / 1GB × 2 tasks** | **~200 RPS · p95 131.6 ms · 0% errors** | `docs/evidence/phase8/load-capacity.txt` |

**Operating tip:** keep **lean** (256/512 ×1) for idle cost; scale to **demo/load profile** (512/1024 ×2) when proving the 200 RPS SLO.

First bottleneck was unbounded `/records` (~300KB responses) — fixed with `LIMIT` + skip empty ILIKE. Writeup: `docs/evidence/phase5/bottleneck-writeup.md`.

---

## Repo map

```text
app/                 FastAPI service, auth, tests, Dockerfile
infra/               Terraform modules + staging/production envs + scripts
observability/       CloudWatch dashboard/alarms, SLOs, error budget
loadtest/            k6 scripts (results/ local only — not required on GitHub)
autopilot/           Reliability Autopilot (policies, CLI, demo, tests)
docs/                Founder, runbooks, cost, 90-day, evidence/
assessment/          Matrix, CURRENT_STATE, source PDF/playbook
.github/workflows/   ci.yml
```

**Do not commit:** `.env`, `.cloud-lab-keys`, `*.tfvars`, tfstate, raw `loadtest/results/*.json` (sanitized copies live under `docs/evidence/`).

---

## Local quick start

```bash
cp .env.example .env
docker compose up --build -d
docker compose exec api python bootstrap_auth.py
docker compose exec -e DATABASE_URL=postgresql://admin:admin123@db:5432/ledgerline \
  -e ADMIN_TOKEN -e API_KEY_PEPPER api python -m pytest
```

Use `Authorization: Bearer <key>` from bootstrap.

```bash
make autopilot-demo    # dry-run remediations + kill switch
make help              # platform / deploy / load / restore targets
```

---

## Staging ops (Mumbai)

- ALB (example): see `assessment/CURRENT_STATE.md`  
- Deploy: `make deploy-staging` · Rollback: `make rollback-staging`  
- Restore drill: `APPROVE_RESTORE=1 make restore-drill`  
- Budget alarm: `ll-staging-monthly` ($75 soft gate)

---

## Known limitations

See [`assessment/KNOWN_LIMITATIONS.md`](assessment/KNOWN_LIMITATIONS.md). Notable: ALB HTTP until ACM domain; prod not applied; stretch multi-region deferred.

---

## AI usage

Cursor / AI assistants were used. Designs remain explainable and candidate-owned for the live founder session.
