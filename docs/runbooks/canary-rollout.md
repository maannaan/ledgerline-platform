# Canary rollout (one tenant first)

## Intent

Ship a risky change to **one tenant** before the rest (Task 4).

## Procedure (staging / assessment)

1. Deploy new image via `./infra/scripts/deploy_staging.sh` (platform-wide binary).
2. **Feature canary via tenant key:** only issue the new client SDK / config to **Acme** first.
3. Monitor 15–30 minutes:
   - Logs Insights: `filter tenant = "acme"`
   - ALB 5xx + latency alarms
   - `/metrics` counters for `tenant="acme"`
4. If healthy, roll config to Brightpath/Cobalt/Delta.
5. If not: `./infra/scripts/rollback_staging.sh` and revoke canary client config.

## Stronger future canary (planned)

- Weighted ALB listener rules or dual target groups per canary image.
- Not required if tenant-scoped config canary + fast rollback is evidenced.
