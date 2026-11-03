# Pre-apply cost & exposure gate (Phase 3)

**Status:** Terraform authored and validated locally. **No `terraform apply` has been run.**

## Proposed services (staging)

| Service | Purpose | Public? |
|---------|---------|---------|
| VPC + 2 public subnets + IGW | Network | N/A |
| ALB | HTTPS/HTTP ingress | Yes (port 80 now; TLS cert later) |
| ECS Fargate (1 task staging) | API | Via ALB only |
| ECR | Images | Private |
| RDS Postgres micro (shared) | Shared tenants | **No** (SG app-only, `publicly_accessible=false`) |
| RDS Postgres micro (Delta) | Dedicated | **No** |
| KMS CMK shared + Delta | Encryption at rest | N/A |
| Secrets Manager | App secrets | Private |
| CloudWatch Logs (7d) | Logs | Private |
| AWS Budgets (optional) | Spend alarm | N/A |

## Region

`ap-south-1` (Mumbai) — set per user request

## Estimated burn (3–4 days)

~$25–40 target / soft max $75 (see plan). Credits available ~$170.

## Budget alert email (configured)

- Staging `terraform.tfvars`: `mananpaliwal30@gmail.com`
- Monthly budget limit: **$75** (80% notification threshold)
- File is gitignored (`*.tfvars`)

## Explicit non-actions until you approve apply

- `terraform apply`
- Pushing images to ECR
- Creating AWS resources that incur charge

## Approve apply by saying

“Approve staging apply” (budget email is already set)
