# Load tests (k6)

Assessment target: **200 RPS for 10 minutes** across **3 tenants**; p95 `/records` **&lt; 300 ms**.

Staging note: brief says “production”; we run controlled **staging** tests and label evidence honestly (cost + safety).

## Prerequisites

- [k6](https://k6.io/docs/get-started/installation/)
- Tenant API keys (never commit): `acme`, `brightpath`, `delta` (or cobalt for noisy)
- `BASE_URL` = staging ALB or local `http://127.0.0.1:8000`

```bash
export BASE_URL=http://ll-staging-alb-1605781679.ap-south-1.elb.amazonaws.com
export TENANTS="acme:KEY1,brightpath:KEY2,delta:KEY3"
```

## Baseline (T5.2)

```bash
make load-baseline
# or:
k6 run -e BASE_URL -e TENANTS -e RATE=200 loadtest/load.js
```

Results → `loadtest/results/` (gitignored summaries OK; sanitize keys).

## Noisy neighbour (T5.3)

```bash
export NOISY=1
export NOISY_KEY="<cobalt_key>"
make load-noisy
```

Compare Acme/Brightpath/Delta p95 before vs during Cobalt `/reports/heavy` traffic.

## Guardrails

- Confirm budget / soft max before a full 10m run against staging.
- Prefer a short smoke first: `RATE=20` duration override via editing or `k6 run --duration 30s` with a copy.
- Do not paste live keys into evidence files.
