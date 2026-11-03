# Runbook: Database restore (Evergreen-class)

**Owner:** on-call platform engineer  
**Authorize:** engineering lead (or founder) before any restore that spends money or changes routing  
**Target:** RTO ≤ 60 minutes · RPO ≤ 15 minutes (PITR / LatestRestorableTime)  
**Proven (staging 2026-11-03):** RTO **8.25 min** · RPO **6.23 min** — `docs/evidence/phase5/restore-drill-20261103T100335Z.json`

## When to use

Customer data loss, corruption, or tenant-scoped disaster on a **dedicated** DB (Evergreen Health; staging stand-in: **Delta** `ll-staging-delta-pg`).

## Procedure

1. **Declare incident** — severity, tenant, region (`ap-south-1`), blast radius.
2. **Freeze writes** if corruption is ongoing (scale API desired=0 or block tenant keys).
3. **Confirm restore point** — note wall-clock incident time and `LatestRestorableTime`:
   ```bash
   aws rds describe-db-instances --region ap-south-1 \
     --db-instance-identifier ll-staging-delta-pg \
     --query 'DBInstances[0].LatestRestorableTime'
   ```
4. **Obtain approval** — record who approved and at what time.
5. **Restore to a NEW instance** (never overwrite source first):
   ```bash
   APPROVE_RESTORE=1 ./infra/scripts/restore_rds_drill.sh
   # optional: SOURCE_DB_ID=... TARGET_DB_ID=... DESTROY_AFTER=1
   ```
6. **Record** start, available time, snapshot id → evidence JSON under `docs/evidence/phase5/`.
7. **Validate** (from a network path that can reach private RDS — ECS task / bastion):
   - schema tables present (`records`, `api_keys`, `admin_audit_events`)
   - row counts for the tenant
   - sample `SELECT` of known ids
8. **Controlled switch** — update Secrets Manager `DATABASE_URL` (or tenant routing) to the restored endpoint; redeploy/restart tasks.
9. **Monitor** 5xx, latency, `/ready`; keep original DB for rollback/forensics ≥ 24h.
10. **Cleanup** — delete drill instance when validation complete (`DESTROY_AFTER=1` or manual delete).

## RTO / RPO measurement

| Metric | How measured |
|--------|----------------|
| RTO | Wall clock from `restore-db-instance-from-db-snapshot` to `db-instance-available` |
| RPO | `incident_time - LatestRestorableTime` (continuous backup / WAL on RDS with retention ≥ 1) |

Do **not** claim RPO from backup frequency alone.

## Rollback

Point Secrets Manager / task definition back to the original instance endpoint; redeploy.
