# Infrastructure (Terraform)

Same modules for **staging** and **production**.

## Layout

- `modules/network` — VPC, public subnets, ALB/app/db security groups (**no NAT** for cost)
- `modules/rds` — encrypted Postgres (shared or dedicated)
- `modules/kms` — CMK (+ dedicated per Delta)
- `modules/secrets` — Secrets Manager app secret
- `modules/ecs_api` — ECR, ALB, Fargate service (circuit breaker rollback)
- `modules/tenant_registry` — SSM tenant inventory
- `modules/budget` — optional AWS Budget email alarm
- `environments/staging|production` — env roots
- `tenants/*.json` — onboard manifests
- `scripts/` — onboard / list / local Acme migration

## One-command flows

```bash
make platform-init ENV=staging
make platform-validate ENV=staging
make platform-plan ENV=staging          # needs AWS creds; does not create resources
make onboard TENANT=brightpath TIER=shared ENV=staging
make onboard TENANT=delta TIER=dedicated ENV=staging
make tenant-list ENV=staging
APPROVE_APPLY=1 make platform-apply ENV=staging   # ONLY after billing alarm + explicit approval
```

## Pre-apply checklist (mandatory)

1. Confirm region (`us-east-1` default) and spend soft max (~$75).
2. Set billing/budget alert email in `terraform.tfvars`.
3. Review public exposure: ALB is internet-facing; **DB is not publicly accessible**.
4. Understand lean network tradeoff: tasks use public IP (no NAT) to save cost.
5. Get explicit human approval for `APPROVE_APPLY=1`.

## Estimated 3–4 day cost (lean)

Target ~$25–40 with shared+Delta micro RDS, 1 Fargate task, ALB, no NAT. Details in `docs/evidence/phase3/PRE_APPLY_COST_GATE.md`.
