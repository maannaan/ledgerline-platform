#!/usr/bin/env bash
# After OIDC assume-role: load CI JSON from ASM and export SONAR_TOKEN / ALB_SMOKE_URL.
set -euo pipefail
SECRET_NAME="${1:?usage: fetch-ci-secret.sh <secret-name>}"
REGION="${AWS_REGION:-ap-south-1}"

RAW=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text)

SONAR_TOKEN=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("SONAR_TOKEN",""))' "$RAW")
ALB_SMOKE_URL=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("ALB_SMOKE_URL",""))' "$RAW")

# Mask token so Actions logs never print it.
if [[ -n "$SONAR_TOKEN" && "$SONAR_TOKEN" != "REPLACE_ME" ]]; then
  echo "::add-mask::${SONAR_TOKEN}"
fi

{
  echo "SONAR_TOKEN=${SONAR_TOKEN}"
  echo "ALB_SMOKE_URL=${ALB_SMOKE_URL}"
} >> "$GITHUB_ENV"

if [[ -z "$SONAR_TOKEN" || "$SONAR_TOKEN" == "REPLACE_ME" ]]; then
  echo "SONAR_READY=false" >> "$GITHUB_ENV"
  echo "WARN: SONAR_TOKEN missing or placeholder in ${SECRET_NAME}; Sonar steps will skip."
else
  echo "SONAR_READY=true" >> "$GITHUB_ENV"
fi
