# Acme Retail production cutover (under 5 minutes downtime)

## Goal

Move Acme from the legacy single-VM Compose stack to the platform shared RDS **without data loss**, with **&lt; 5 minutes** write downtime.

## Local rehearsal

```bash
make migrate-acme-local
```

This copies Acme rows into a fresh Postgres database and verifies counts. Evidence: `docs/evidence/phase3/acme-local-migration.txt`.

## Production approach (expand → catch-up → cutover)

1. **Expand**
   - Provision target shared RDS (Terraform) and schema (`records`, `api_keys`, audit tables).
   - Create Acme API keys in target; keep old stack serving traffic.
2. **Bulk baseline copy** (online)
   - `COPY` / logical dump of Acme rows to target while old system still takes writes.
   - Record watermark (`created_at` / `id`).
3. **Catch-up**
   - Prefer PostgreSQL logical replication / continuous sync if privileges allow.
   - Fallback: periodic delta copy `WHERE id > :watermark OR created_at > :watermark`.
4. **Cutover window (&lt; 5 minutes)**
   - Enable maintenance / reject writes on old API (or freeze Acme key).
   - Final delta copy + count/checksum compare.
   - Switch ALB/DNS or tenant registry `db_target` to new platform.
   - Smoke: create/list record with Acme key; isolation test sample.
5. **Verify**
   - Row counts match; sample payload hashes; `/ready` healthy; error rate baseline.
6. **Rollback**
   - Keep old stack warm for ≥24h.
   - Re-point traffic to old endpoint; do **not** delete old data until soak succeeds.

## What we claim vs do not claim

- **Claim:** Rehearsed seed migration with measured elapsed time + documented &lt;5 min cutover procedure.
- **Do not claim:** Production CDC was implemented unless a cloud rehearsal with replication was actually run and evidenced.

## Checksums

```sql
SELECT count(*), md5(string_agg(id::text || payload::text, ',' ORDER BY id))
FROM records WHERE tenant_id = 'acme';
```
