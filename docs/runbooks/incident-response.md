# Runbook: Incident response

**Owner:** incident lead (rotate)  
**Comms:** status channel + email for Sev-1 customers  
**Related:** `database-restore.md`, `deploy-rollback.md`, CloudWatch alarms → SNS

## Severity

| Sev | Example | Response |
|-----|---------|----------|
| 1 | Data loss risk, auth bypass, all tenants down | Page immediately; executive notify |
| 2 | Elevated 5xx / p95 breach, single-tenant outage | Respond &lt; 15m |
| 3 | Degraded non-critical path (heavy reports) | Business hours |

## Procedure

1. **Detect & acknowledge**
   - Source: CloudWatch alarm (`ledgerline-staging-5xx` / latency / unhealthy-hosts), CI fail, customer report  
   - Acknowledge in channel; assign **incident lead** + scribe

2. **Blast radius**
   - Env: staging vs prod  
   - Scope: all tenants vs one (`tenant` log field / API key)  
   - Data/security: read-only degradation vs corruption / leak  

3. **Preserve evidence**
   - Note `request_id` / `trace_id` from JSON logs  
   - Capture current task def revision, image digest, recent deploy time  
   - Do **not** rotate logs away mid-incident without copying samples

4. **Mitigate (prefer reversible)**
   | Symptom | First action | Guardrail |
   |---------|--------------|-----------|
   | Bad deploy / health fail | `make rollback-staging` | Known prior digest only |
   | Task crash loop | Let ECS replace; check `/ready` | Cap force-deploys |
   | Latency / saturation | Scale desired count within budget; shed `/reports/heavy` via concurrency already in app | Soft max spend |
   | Tenant abuse / noisy | Revoke key or keep heavy 429 path | No cross-tenant data wipe |
   | Corruption / loss | Freeze writes → `database-restore.md` | New instance first; approval required |

5. **Verify recovery**
   - `/health` + `/ready` 200  
   - Alarm clear; p95 / 5xx back to baseline  
   - Spot-check 2 tenants create+list  

6. **Communicate**
   - Update every 15–30m while Sev-1/2 open: impact, mitigation, next check-in time  
   - Resolve note when verified  

7. **Close & hand off**
   - Timeline + links in ticket  
   - Schedule blameless PIR within 3 business days (`docs/post-incident-review.md`)

## Contacts (assessment)

- Budget / SNS: `mananpaliwal30@gmail.com`  
- Region: `ap-south-1`  
- ALB staging: see `assessment/CURRENT_STATE.md`
