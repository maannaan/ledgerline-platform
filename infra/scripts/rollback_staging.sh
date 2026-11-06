#!/usr/bin/env bash
# Local one-step rollback: prefer IMAGE_TAG; else previous task def revision.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION="${AWS_REGION:-ap-south-1}"

if [[ -n "${IMAGE_TAG:-}" ]]; then
  exec "$ROOT/infra/scripts/rollback_env.sh" staging "$IMAGE_TAG"
fi

PREV_FILE="$ROOT/.last-taskdef-staging"
if [[ -f "$PREV_FILE" ]]; then
  PREV=$(cat "$PREV_FILE")
else
  CURRENT=$(aws ecs describe-services --region "$REGION" --cluster ll-staging-cluster \
    --services ll-staging-api --query 'services[0].taskDefinition' --output text)
  FAMILY=${CURRENT%:*}
  REV=${CURRENT##*:}
  PREV="${FAMILY}:$((REV-1))"
fi
echo "Rolling back to task definition ${PREV} (set IMAGE_TAG=... for tag-based rollback)"
aws ecs update-service --region "$REGION" --cluster ll-staging-cluster \
  --service ll-staging-api --task-definition "$PREV" --force-new-deployment >/dev/null
echo "rollback_started taskdef=${PREV}"
