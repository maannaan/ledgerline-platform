# Deploy & one-step rollback

## Deploy (zero downtime)

```bash
./infra/scripts/deploy_staging.sh
```

- Builds `linux/amd64` image, pushes tag + digest to ECR
- Registers new ECS task definition pinned to digest
- ECS rolling deploy + **circuit breaker with rollback** (Terraform)

## Rollback (one step)

```bash
./infra/scripts/rollback_staging.sh
```

Restores previous task definition and force-deploys.

## Safe DB migrations

See `docs/decisions/safe-migrations.md` (expand/contract). Never combine destructive schema drops with the release that depends on the new shape.
