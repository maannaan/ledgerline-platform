#!/usr/bin/env bash
set -euo pipefail
ENV="${1:?env}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="$ROOT/infra/tenants/${ENV}.json"
TF_DIR="$ROOT/infra/environments/${ENV}"

echo "=== Manifest ${MANIFEST} ==="
if [[ -f "$MANIFEST" ]]; then
  python3 -m json.tool <"$MANIFEST"
else
  echo "(missing — run make onboard first)"
fi

echo
echo "=== Terraform output tenant_inventory (if state exists) ==="
if [[ -f "$TF_DIR/terraform.tfstate" ]]; then
  (cd "$TF_DIR" && terraform output -json tenant_inventory | python3 -m json.tool)
else
  echo "(no terraform state yet — expected before first apply; manifest above is source of intent)"
fi
