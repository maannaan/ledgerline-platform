# Ledgerline Platform

Predixion AI — Founding Reliability Engineer live assessment.

## Start here

1. [`assessment/CURRENT_STATE.md`](assessment/CURRENT_STATE.md) — session handoff  
2. [`assessment/SOURCE_OF_TRUTH.md`](assessment/SOURCE_OF_TRUTH.md) — requirements source  
3. [`AGENTS.md`](AGENTS.md) — how agents/humans work this repo  
4. [`docs/GITHUB_FIRST_PUSH.md`](docs/GITHUB_FIRST_PUSH.md) — **you** commit + push (agent will not)

## What this is

Multi-tenant B2B SaaS: take a fragile FastAPI + Postgres lab and make it secure, operable, and multi-tenant ready (shared + dedicated tiers).

## Current status (Phase 4)

- Authenticated multi-tenant API + isolation tests
- Staging in **ap-south-1** (ECS/Fargate, ALB, RDS, KMS, Secrets Manager, budgets)
- Observability: JSON logs, Prometheus `/metrics`, CloudWatch dashboard + alarms
- Safe deploy/rollback Make targets; GitHub Actions workflow ready
- TLS: optional ACM hook — needs your domain (`docs/runbooks/enable-tls.md`)

## Quick local start

```bash
cp .env.example .env   # or use existing lab .env
docker compose up --build -d
docker compose exec api python bootstrap_auth.py
docker compose exec -e DATABASE_URL=postgresql://admin:admin123@db:5432/ledgerline \
  -e ADMIN_TOKEN -e API_KEY_PEPPER api python -m pytest
```

Call API with `Authorization: Bearer <tenant_key>` from bootstrap output.

## AI usage

Cursor / AI coding assistants are used for this assessment. All designs must remain explainable and modifiable by the candidate in the live session.

## Unfinished work

See [`assessment/REQUIREMENTS_MATRIX.md`](assessment/REQUIREMENTS_MATRIX.md) and [`assessment/KNOWN_LIMITATIONS.md`](assessment/KNOWN_LIMITATIONS.md).
