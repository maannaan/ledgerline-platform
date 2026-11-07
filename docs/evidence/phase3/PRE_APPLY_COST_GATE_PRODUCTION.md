# Pre-apply cost & exposure gate — production (lean)

**Status:** **APPLIED** 2026-11-07 — lean production live alongside staging.  
**Date:** 2026-11-07  
**ALB:** `http://ll-production-alb-2062045131.ap-south-1.elb.amazonaws.com`  
**Evidence:** `terraform-apply-production-ap-south-1.txt`, `deploy-production.txt`, `production-smoke.txt`

## Proposed services (production)

Same modules as staging; name prefix `ll-production-*`; VPC `10.40.0.0/16`.

| Service | Purpose | Public? |
|---------|---------|---------|
| VPC + 2 public subnets + IGW | Network | N/A |
| ALB | HTTP ingress | Yes (port 80; TLS deferred) |
| ECS Fargate (**1** task lean) | API | Via ALB only |
| ECR | Images | Private |
| RDS Postgres micro (shared) | Shared tenants | **No** |
| RDS Postgres micro (Delta) | Dedicated | **No** |
| KMS CMK shared + Delta | Encryption at rest | N/A |
| Secrets Manager | App secrets | Private |
| CloudWatch Logs | Logs | Private |
| AWS Budgets | Spend alarm | Email alert |
| GitHub OIDC role | CD (provider already exists) | N/A |

## Lean overrides (assessment)

- `deletion_protection = false` (tear down within 48h after live session)
- `api_desired_count = 1`
- `db_backup_retention_days = 7`
- Tenants match staging (acme, brightpath, cobalt, harbor + delta)

## Estimated burn

| Item | Estimate |
|------|----------|
| Staging already running | ~$2–8/day lean |
| Adding production | roughly another ~$2–8/day |
| Dual-env ~1–2 days | order-of $8–30 extra vs staging-only |

Working budget: target ~$25–40 / soft max $75 / hard check $100.

## Budget alert

- Email: `mananpaliwal30@gmail.com`
- Monthly limit: **$75**

## Explicit non-actions until APPROVE_APPLY=1

- `terraform apply` on production
- Pushing images to prod ECR
- Creating billable AWS resources for `ll-production-*`

## Out of scope this apply

- Prod 200 RPS load / restore drill
- TLS / domain
- Destroy (separate approve after live session)
