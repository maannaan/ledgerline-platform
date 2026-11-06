# Deploy & one-step rollback

## Secrets policy

**No GitHub Actions secrets.** Pipelines authenticate with **GitHub OIDC → IAM role** (`ll-{env}-gha`), then read CI tokens from **AWS Secrets Manager** `ll-{env}/ci`.

| Item | Location |
|------|----------|
| Role ARN | Committed [`.github/workflows/aws-role-arns.json`](../../.github/workflows/aws-role-arns.json) |
| `SONAR_TOKEN`, `ALB_SMOKE_URL` | ASM `ll-staging/ci` / `ll-production/ci` |
| App DB/admin/pepper | ASM `ll-{env}/app` (ECS task role) |

### Put Sonar token in ASM (once)

```bash
# After terraform apply creates ll-staging/ci
aws secretsmanager get-secret-value --region ap-south-1 --secret-id ll-staging/ci \
  --query SecretString --output text > /tmp/ci.json
# edit SONAR_TOKEN in /tmp/ci.json (do not commit)
aws secretsmanager put-secret-value --region ap-south-1 --secret-id ll-staging/ci \
  --secret-string file:///tmp/ci.json
rm /tmp/ci.json
```

Create a SonarCloud project and align `sonar.organization` / `sonar.projectKey` in `sonar-project.properties`.

## Local deploy (tag + digest)

```bash
make deploy-env ENV=staging IMAGE_TAG=$(git rev-parse --short HEAD)
# or legacy:
make deploy-staging
```

- Builds `linux/amd64`, pushes ECR tag, deploys ECS task def pinned to **digest**
- ECS rolling deploy + circuit breaker

## Local rollback by tag (preferred)

```bash
make rollback-env ENV=staging IMAGE_TAG=<known-good-tag>
```

Redeploys the existing ECR tag’s digest (no rebuild).

Legacy without tag (previous task def revision):

```bash
make rollback-staging
# or IMAGE_TAG=abc1234 make rollback-staging
```

## GitHub Actions CD (manual, parameterized)

Actions → **cd** → Run workflow:

| Input | Meaning |
|-------|---------|
| `environment` | `staging` \| `production` |
| `image_tag` | Empty on deploy → short SHA; **required** for rollback |
| `confirm_production` | Must be `DEPLOY` for production deploy/rollback |
| `run_tests` / `run_sonar` / `run_security_scan` / `run_terraform_validate` | Optional gates |
| `run_build_push` | Build + push ECR tag |
| `run_deploy` | ECS update to that tag’s digest |
| `run_rollback` | ECS update to existing tag (mutually exclusive with deploy) |

Examples:

1. **Promote staging:** tests + security + build_push + deploy, `environment=staging`, leave `image_tag` empty.
2. **Rollback staging:** `run_rollback=true`, `image_tag=<previous-sha>`, all other run_* false.
3. **Production:** same as promote but `environment=production` and `confirm_production=DEPLOY` (fails until prod stack is applied).

OIDC roles are created by Terraform module `github_oidc`. Trust allows both classic `repo:owner/repo:*` and GitHub nBF subjects `repo:owner@ID/repo@ID:*`.

**Ask before** `APPROVE_APPLY=1 make platform-apply ENV=staging` to create/update roles/secret.

## Safe DB migrations

See `docs/decisions/safe-migrations.md` (expand/contract). Never combine destructive schema drops with the release that depends on the new shape.
