# Cost Model

**Status:** Skeleton — fill with calculator exports / actual bills in Phase 6.

## Assumptions (working)

- Region: ap-south-1 (Mumbai)  
- Window: 3–4 days assessment cloud uptime  
- Credits available: ~$170  
- Target burn: ~$25–40; soft max $75  
- Lean network: **no NAT**; Fargate `assign_public_ip`; RDS not publicly accessible  

## Staging stack drivers (from Phase 3 IaC)

| Component | Assumed size | Role |
|-----------|--------------|------|
| ALB | 1 | Ingress |
| ECS Fargate | 0.25 vCPU / 0.5 GB × 1 | API |
| RDS Postgres | db.t4g.micro × 2 (shared + Delta) | Data |
| KMS | 2 keys | Shared + Delta |
| Secrets Manager | 1 secret | App config |
| CloudWatch Logs | 7-day retention | Ops |

## Monthly-style estimate (to complete)

| Component | Shared tenant marginal | Dedicated tenant marginal | Notes |
|-----------|------------------------|---------------------------|-------|
| Compute (ECS) | TBD | TBD | |
| Database (RDS) | TBD (pooled share) | TBD (own instance) | |
| Storage / backup | TBD | TBD | |
| LB / data transfer | TBD | TBD | |
| Logs / metrics | TBD | TBD | |
| KMS / secrets | TBD | TBD (own key) | |
| **Total** | TBD | TBD | |

Separate fixed platform cost from per-tenant marginal cost. Label estimates vs measured.
