# Demo Runbook

## Prerequisites

- Phase completion noted in `assessment/CURRENT_STATE.md`
- No fabricated output — paste real command results into `docs/evidence/`

## Phase 0 demo (repo readiness)

```bash
cd /Users/apple/Desktop/Manan/ledgerline-platform
git rev-parse --show-toplevel   # must be this directory
ls app assessment/source loadtest docs
```

## Phase 1 demo (fragile baseline)

```bash
docker compose up -d
curl -s http://127.0.0.1:8000/health
# Cross-tenant IDOR (use a brightpath id from create):
curl -s http://127.0.0.1:8000/records/3
# SQL injection dumps other tenants while "being" acme:
curl -sG http://127.0.0.1:8000/records --data-urlencode "search=' OR 1=1 --" -H 'X-Tenant-Id: acme' | head
# Token leak in logs after admin delete with default token:
docker compose logs api | grep 'using token'
```

Evidence saved under `docs/evidence/phase1/`.

## Phase 2 demo (isolation fixed)

```bash
docker compose up -d
docker compose exec api python bootstrap_auth.py
# Use keys from bootstrap output / local .env SEED_API_KEYS

curl -s http://127.0.0.1:8000/records   # 401
curl -s -X POST http://127.0.0.1:8000/records \
  -H "Authorization: Bearer $BRIGHTPATH_KEY" -H 'Content-Type: application/json' \
  -d '{"sku":"SECRET"}'
# Capture id, then as Acme:
curl -s http://127.0.0.1:8000/records/$ID -H "Authorization: Bearer $ACME_KEY"   # 404
curl -s http://127.0.0.1:8000/records -H "Authorization: Bearer $ACME_KEY" -H 'X-Tenant-Id: brightpath'  # 403

docker compose exec -e DATABASE_URL=postgresql://admin:admin123@db:5432/ledgerline \
  -e ADMIN_TOKEN -e API_KEY_PEPPER api python -m pytest
```

Evidence: `docs/evidence/phase2/`.

## Phase 3 cloud demo (Mumbai staging)

```bash
ALB=http://ll-staging-alb-1605781679.ap-south-1.elb.amazonaws.com
curl -s $ALB/health
curl -s $ALB/ready
# keys in gitignored .cloud-lab-keys
source .cloud-lab-keys   # or export ACME key manually
curl -s -X POST $ALB/records -H "Authorization: Bearer ll_acme_cloud_ap_south_1" \
  -H 'Content-Type: application/json' -d '{"sku":"DEMO"}'
curl -s $ALB/records -H "Authorization: Bearer ll_acme_cloud_ap_south_1" -H 'X-Tenant-Id: brightpath'
# expect 403
```

## Phase 4 demo (delivery + observability)

```bash
# Metrics + JSON logs (local or ALB)
curl -s http://ll-staging-alb-1605781679.ap-south-1.elb.amazonaws.com/metrics | head
make deploy-staging      # digest pin
make rollback-staging    # one step
# AWS Console → CloudWatch → Dashboards → Ledgerline-Staging
# Alarms: ledgerline-staging-5xx / latency / unhealthy-hosts
```

## Phase 5–6 demo (recovery + ops)

```bash
# Restore evidence (do not re-create RDS unless APPROVE_RESTORE=1):
cat docs/evidence/phase5/restore-drill-20261103T100335Z.json
# Load / noisy / bottleneck honesty:
head -40 docs/evidence/phase5/load-baseline-tuned.txt
head -30 docs/evidence/phase5/load-noisy.txt
# Ops pack:
ls docs/runbooks/onboarding.md docs/runbooks/database-restore.md \
   docs/runbooks/incident-response.md docs/post-incident-review.md \
   docs/COST_MODEL.md docs/90_DAY_PLAN.md
```

## Phase 7 demo (Reliability Autopilot)

```bash
make autopilot-demo
# Shows: rollback dry-run, scale-within-cap dry-run, restore BLOCKED, kill switch
make autopilot-test   # 4 unit tests
```

## Optional later

1. Capacity re-test after vertical scale  

