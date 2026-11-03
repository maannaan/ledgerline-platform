# Dashboards

- `ledgerline-staging.json` — CloudWatch dashboard definition (platform health + tenant filter via logs).
- Apply with: `./observability/scripts/apply_cloudwatch.sh`

Widgets:

1. ALB request count / 5xx  
2. Target response time  
3. Healthy/unhealthy host count  
4. ECS CPU/memory  
5. Log Insights panel filtered by `tenant` JSON field  
