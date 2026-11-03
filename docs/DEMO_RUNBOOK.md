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

## Later demos

1. Evergreen restore timing  
2. k6 200 RPS + Cobalt noisy neighbour  
3. Autopilot dry-run + kill switch  

