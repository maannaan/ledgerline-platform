#!/usr/bin/env bash
# Idempotent tenant onboarding helper.
# Updates tenant manifests and prints the Terraform / runtime steps.
# Does NOT run terraform apply unless APPROVE_APPLY=1.
set -euo pipefail

ENV="${1:?env}"
TENANT="${2:?tenant}"
TIER="${3:?tier}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST_DIR="$ROOT/infra/tenants"
MANIFEST="$MANIFEST_DIR/${ENV}.json"
TF_DIR="$ROOT/infra/environments/${ENV}"

mkdir -p "$MANIFEST_DIR"
if [[ ! -f "$MANIFEST" ]]; then
  cat >"$MANIFEST" <<'EOF'
{
  "shared_tenants": [],
  "dedicated_tenants": {}
}
EOF
fi

python3 - "$MANIFEST" "$TENANT" "$TIER" <<'PY'
import json, sys
path, tenant, tier = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
shared = list(data.get("shared_tenants") or [])
dedicated = dict(data.get("dedicated_tenants") or {})
if tier == "shared":
    if tenant not in shared:
        shared.append(tenant)
    dedicated.pop(tenant, None)
else:
    if tenant in shared:
        shared.remove(tenant)
    dedicated.setdefault(tenant, {
        "notes": f"Dedicated tenant {tenant}",
        "instance_class": "db.t4g.micro",
        "backup_retention_days": 7,
    })
data["shared_tenants"] = sorted(set(shared))
data["dedicated_tenants"] = dedicated
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"updated {path}")
print(json.dumps(data, indent=2))
PY

# Write/refresh terraform.tfvars.json from manifest (keeps env defaults mergeable)
python3 - "$MANIFEST" "$TF_DIR/tenant.auto.tfvars.json" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    data = json.load(f)
with open(dst, "w") as f:
    json.dump({
        "shared_tenants": data["shared_tenants"],
        "dedicated_tenants": data["dedicated_tenants"],
    }, f, indent=2)
    f.write("\n")
print(f"wrote {dst}")
PY

echo
echo "Onboard prepared for tenant=${TENANT} tier=${TIER} env=${ENV}"
echo "Next:"
echo "  1) Review ${TF_DIR}/tenant.auto.tfvars.json"
echo "  2) make platform-plan ENV=${ENV}"
echo "  3) After billing alarm + approval: APPROVE_APPLY=1 make platform-apply ENV=${ENV}"
echo "  4) Bootstrap API keys into the target DB (shared or dedicated endpoint)"
echo "  5) make tenant-list ENV=${ENV}"
if [[ "${APPROVE_APPLY:-}" == "1" ]]; then
  echo "APPROVE_APPLY=1 set — running terraform apply"
  (cd "$TF_DIR" && terraform apply -input=false)
fi
