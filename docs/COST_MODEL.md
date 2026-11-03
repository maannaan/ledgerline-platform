# Cost Model — Ledgerline (ap-south-1)

**Label:** **Estimates** from public AWS pricing pages / sizing assumptions (Nov 2026).  
Not a Cost Explorer export — CE for this account showed near-$0 / credit lag during assessment days.  
**Working budget:** target ~$25–40 for the 3–4 day window · soft max $75 · hard check $100 vs ~$170 credits.

## Assumptions

| Item | Value |
|------|--------|
| Region | Mumbai (`ap-south-1`) |
| Network | **No NAT**; Fargate public IP; RDS private |
| API | 1× Fargate 0.25 vCPU / 0.5 GB (scale to 2 only during load drills) |
| Shared DB | 1× `db.t4g.micro` Postgres, 20 GB gp3, 7-day backup |
| Dedicated DB | 1× `db.t4g.micro` per dedicated tenant (Delta today) |
| KMS | 1 shared + 1 per dedicated tenant |
| ALB | 1 ALB · light LCU |
| Logs | 7-day retention, low cardinality metrics |

## Fixed platform monthly (always on)

| Component | Low | Expected | High | Notes |
|-----------|-----|----------|------|-------|
| ALB | $16 | $22 | $35 | Hours + LCU; demo traffic spikes High |
| ECS Fargate API (1 task) | $8 | $12 | $25 | 2 tasks / larger CPU → High |
| RDS shared t4g.micro + storage/backup | $12 | $18 | $28 | Instance + 20–50 GB + backup |
| Secrets Manager | $0.40 | $0.50 | $1 | 1 secret + API calls |
| KMS shared | $1 | $1 | $2 | Key/month + requests |
| CloudWatch logs/metrics/alarms | $2 | $5 | $15 | Log volume is the driver |
| Data transfer / public IP | $1 | $3 | $10 | Egress from API |
| **Fixed subtotal** | **~$40** | **~$62** | **~$116** | |

Assessment **short window** cost ≪ monthly: rough **$2–8/day** expected on this lean stack if idle-ish; load + restore drills add spikes.

## Marginal cost per tenant / month

| Driver | Shared tenant | Dedicated tenant | Notes |
|--------|---------------|------------------|-------|
| Compute share | ~$0–2 | $0 (same API) | Contended on shared DB |
| Database | ~$2–4 (slice of shared RDS) | **+$15–25** own `t4g.micro` | Dominant dedicated cost |
| Storage/backup | small | **+$2–5** | Grows with retention |
| KMS | $0 (shared key) | **+$1** | Delta requirement |
| Isolation ops toil | low | medium | Extra restore/on-call surface |
| **Marginal total** | **~$2–6** | **~$18–31** | |

## Scenarios (8 clients mix)

Assume 6 shared + 2 dedicated (Delta + Evergreen-class):

| Scenario | Math | Monthly |
|----------|------|---------|
| Low | Fixed low + 6×$2 + 2×$18 | ~$40 + $12 + $36 ≈ **$88** |
| Expected | Fixed exp + 6×$4 + 2×$22 | ~$62 + $24 + $44 ≈ **$130** |
| High | Fixed high + traffic + 2× larger RDS | **$200+** |

## Cost drivers (what moves the bill)

1. **Dedicated RDS count** — largest step function  
2. **NAT** (avoided here) — would add tens $/month  
3. **Log ingestion** — unbounded debug logs  
4. **Fargate size × count** during load tests  
5. **Restore drills** — temporary second instance until deleted  

## Controls in this repo

- `APPROVE_APPLY=1` / `APPROVE_RESTORE=1` gates  
- AWS Budget module → email `mananpaliwal30@gmail.com` ($75 staging limit)  
- `DESTROY_AFTER=1` on restore drill  
- Scale API back to 1 task after load  

## Shared vs dedicated product framing

- **Shared:** low marginal cost; noisy-neighbour risk managed in app (tenant filters, heavy-report caps).  
- **Dedicated:** pay for isolation + own encryption key + independent restore — priced as premium SKU (~$20+/mo infra before margin).
