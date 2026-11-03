#!/usr/bin/env bash
# Evergreen-class restore drill: restore latest automated snapshot into a NEW RDS instance.
# Does NOT overwrite the source. Requires explicit APPROVE_RESTORE=1.
# Measures wall-clock RTO (create → available) and RPO vs LatestRestorableTime.
set -euo pipefail

APPROVE_RESTORE="${APPROVE_RESTORE:-0}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
SOURCE_DB_ID="${SOURCE_DB_ID:-ll-staging-delta-pg}"
TARGET_DB_ID="${TARGET_DB_ID:-ll-staging-evergreen-restore-$(date -u +%Y%m%d%H%M)}"
INSTANCE_CLASS="${INSTANCE_CLASS:-db.t4g.micro}"
EVIDENCE_DIR="${EVIDENCE_DIR:-docs/evidence/phase5}"
DESTROY_AFTER="${DESTROY_AFTER:-0}"

if [[ "$APPROVE_RESTORE" != "1" ]]; then
  echo "Refusing restore. Re-run with APPROVE_RESTORE=1 after cost approval."
  echo "Creates a temporary RDS instance (~same class as source) billed until deleted."
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"
EVIDENCE_FILE="${EVIDENCE_DIR}/restore-drill-$(date -u +%Y%m%dT%H%M%SZ).json"

echo "== Source instance =="
aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$SOURCE_DB_ID" \
  --query 'DBInstances[0].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass,LatestRestorable:LatestRestorableTime,BackupRetention:BackupRetentionPeriod,Encrypted:StorageEncrypted}' \
  --output json | tee "${EVIDENCE_DIR}/source-db.json"

LATEST_RESTORABLE="$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier "$SOURCE_DB_ID" \
  --query 'DBInstances[0].LatestRestorableTime' --output text)"

echo "== Latest automated snapshot =="
SNAPSHOT_ID="$(aws rds describe-db-snapshots --region "$AWS_REGION" \
  --db-instance-identifier "$SOURCE_DB_ID" --snapshot-type automated \
  --query 'reverse(sort_by(DBSnapshots,&SnapshotCreateTime))[0].DBSnapshotIdentifier' \
  --output text)"
if [[ -z "$SNAPSHOT_ID" || "$SNAPSHOT_ID" == "None" ]]; then
  echo "No automated snapshot yet. Wait for first backup window or create a manual snapshot."
  exit 1
fi
echo "Using snapshot: $SNAPSHOT_ID"

INCIDENT_TIME_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_EPOCH="$(date +%s)"
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "== Restore to fresh instance $TARGET_DB_ID =="
aws rds restore-db-instance-from-db-snapshot \
  --region "$AWS_REGION" \
  --db-instance-identifier "$TARGET_DB_ID" \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --db-instance-class "$INSTANCE_CLASS" \
  --no-publicly-accessible \
  --tags Key=Project,Value=ledgerline Key=Purpose,Value=evergreen-restore-drill Key=Source,Value="$SOURCE_DB_ID" \
  >/dev/null

echo "Waiting until available (this is the RTO clock)..."
aws rds wait db-instance-available --region "$AWS_REGION" --db-instance-identifier "$TARGET_DB_ID"

END_EPOCH="$(date +%s)"
END_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RTO_SECONDS=$((END_EPOCH - START_EPOCH))

# RPO: seconds between LatestRestorableTime and declared incident time.
python3 - "$LATEST_RESTORABLE" "$INCIDENT_TIME_UTC" "$RTO_SECONDS" "$START_UTC" "$END_UTC" \
  "$SOURCE_DB_ID" "$TARGET_DB_ID" "$SNAPSHOT_ID" "$EVIDENCE_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone

def parse(ts: str) -> datetime:
    ts = ts.replace("Z", "+00:00")
    return datetime.fromisoformat(ts).astimezone(timezone.utc)

latest, incident, rto_s, start, end, src, tgt, snap, out = sys.argv[1:10]
latest_dt, incident_dt = parse(latest), parse(incident)
rpo_s = max(0, int((incident_dt - latest_dt).total_seconds()))
payload = {
    "drill": "evergreen_class_restore",
    "source_db": src,
    "target_db": tgt,
    "snapshot_id": snap,
    "incident_time_utc": incident,
    "latest_restorable_time_utc": latest,
    "restore_start_utc": start,
    "restore_available_utc": end,
    "rto_seconds": int(rto_s),
    "rto_minutes": round(int(rto_s) / 60.0, 2),
    "rpo_seconds": rpo_s,
    "rpo_minutes": round(rpo_s / 60.0, 2),
    "targets": {"rto_max_seconds": 3600, "rpo_max_seconds": 900},
    "rto_met": int(rto_s) <= 3600,
    "rpo_met": rpo_s <= 900,
    "notes": [
        "Restore into NEW instance (source not overwritten).",
        "Connectivity validation: private RDS — use ECS one-off or temporary jump after SG allow.",
        "Delta dedicated stands in for Evergreen Health on staging.",
    ],
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
print(json.dumps(payload, indent=2))
PY

if [[ "$DESTROY_AFTER" == "1" ]]; then
  echo "== DESTROY_AFTER=1: deleting restored instance =="
  aws rds delete-db-instance --region "$AWS_REGION" \
    --db-instance-identifier "$TARGET_DB_ID" \
    --skip-final-snapshot >/dev/null
  echo "Delete initiated for $TARGET_DB_ID"
else
  echo "Left $TARGET_DB_ID running. Delete when done to stop billing:"
  echo "  aws rds delete-db-instance --region $AWS_REGION --db-instance-identifier $TARGET_DB_ID --skip-final-snapshot"
fi

echo "Evidence: $EVIDENCE_FILE"
