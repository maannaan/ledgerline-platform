# Architecture (proposed)

## Intent

Proportional multi-tenant SaaS platform on **AWS** for the assessment week. Same Terraform modules for staging and production. Prefer managed services; avoid Kubernetes.

## High-level

```text
Clients → ALB (TLS) → ECS Fargate (FastAPI)
                         ├─ Auth / tenant resolver (server-derived)
                         ├─ Shared RDS PostgreSQL (+ RLS / scoped queries)
                         ├─ Dedicated RDS (Delta; Evergreen restore path)
                         ├─ Secrets Manager + KMS (per-dedicated key where required)
                         └─ CloudWatch / OpenTelemetry (tenant-aware, bounded cardinality)
CI (GitHub Actions OIDC) → ECR → ECS deploy (canary → promote, one-step rollback)
```

## Tenant model

- Registry: tenant id, tier, region, DB target, KMS key ref, status, limits.
- Auth: bearer API key → hashed lookup → tenant + role. `X-Tenant-Id` is never authority.
- Shared: pooled DB, mandatory tenant scope (+ RLS if implemented correctly).
- Dedicated: separate database + encryption key; routing only via server registry.

## Local baseline

- Hardened Compose API (Phase 2) + Postgres 16 with seeded Acme/Cobalt data.

## IaC status (Phase 3)

- Modules under `infra/modules/*`; env roots `staging` / `production`.
- Lean networking: public subnets + Fargate public IP (**no NAT**); RDS SG-locked, not publicly accessible.
- Shared RDS+KMS for pooled tenants; **Delta** dedicated RDS+KMS via `for_each`.
- Apply gated by `APPROVE_APPLY=1` — not yet executed.

## Cloud spend posture

- Region: **ap-south-1 (Mumbai)** — staging applied.
- 3–4 day window; ~$170 credits available.
- Target ~$25–40; soft max $75; hard check $100.
- See `docs/evidence/phase3/PRE_APPLY_COST_GATE.md`.
