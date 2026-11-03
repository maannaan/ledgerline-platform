#!/usr/bin/env bash
# Demonstrate Acme seed migration locally: copy records into a fresh logical DB
# and verify counts. Production cutover narrative is in docs/runbooks/acme-cutover.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SRC_DB="${SRC_DB:-ledgerline}"
DST_DB="${DST_DB:-ledgerline_acme_cutover}"
PG="docker compose exec -T db psql -U admin -v ON_ERROR_STOP=1"

echo "Ensuring source has acme rows..."
$PG -d "$SRC_DB" -c "SELECT count(*) AS acme_count FROM records WHERE tenant_id='acme';"

echo "Creating destination database ${DST_DB} (idempotent)..."
$PG -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='${DST_DB}'" | grep -q 1 \
  || $PG -d postgres -c "CREATE DATABASE ${DST_DB};"

echo "Copying schema + acme data via dump/restore..."
docker compose exec -T db bash -lc "
  pg_dump -U admin -d ${SRC_DB} --schema-only > /tmp/schema.sql
  pg_dump -U admin -d ${SRC_DB} --data-only --table=records \
    --column-inserts | sed -n '/tenant_id.*acme\\|INSERT INTO records/p' > /tmp/acme_data.sql || true
"

# Cleaner approach: schema + filtered copy with SQL
$PG -d "$DST_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS records (
  id SERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
TRUNCATE records RESTART IDENTITY;
SQL

START=$(date +%s)
$PG -d "$SRC_DB" -c "\\copy (SELECT tenant_id, payload, created_at FROM records WHERE tenant_id='acme') TO STDOUT" \
  | $PG -d "$DST_DB" -c "\\copy records(tenant_id, payload, created_at) FROM STDIN"
END=$(date +%s)

SRC_COUNT=$($PG -d "$SRC_DB" -Atc "SELECT count(*) FROM records WHERE tenant_id='acme'")
DST_COUNT=$($PG -d "$DST_DB" -Atc "SELECT count(*) FROM records WHERE tenant_id='acme'")
echo "source_acme=${SRC_COUNT} dest_acme=${DST_COUNT} elapsed_seconds=$((END-START))"
if [[ "$SRC_COUNT" != "$DST_COUNT" ]]; then
  echo "COUNT MISMATCH" >&2
  exit 1
fi
echo "Local Acme migration rehearsal OK"
mkdir -p docs/evidence/phase3
{
  echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source_acme=${SRC_COUNT}"
  echo "dest_acme=${DST_COUNT}"
  echo "elapsed_seconds=$((END-START))"
} | tee docs/evidence/phase3/acme-local-migration.txt
