#!/usr/bin/env bash
# One-step rollback to previous task definition.
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"
PREV_FILE=".last-taskdef-staging"
if [[ ! -f "$PREV_FILE" ]]; then
  echo "No ${PREV_FILE}. Falling back to previous ECS task definition revision."
  CURRENT=$(aws ecs describe-services --region "$REGION" --cluster ll-staging-cluster \
    --services ll-staging-api --query 'services[0].taskDefinition' --output text)
  FAMILY=${CURRENT%:*}
  REV=${CURRENT##*:}
  PREV="${FAMILY}:$((REV-1))"
else
  PREV=$(cat "$PREV_FILE")
fi
echo "Rolling back to ${PREV}"
aws ecs update-service --region "$REGION" --cluster ll-staging-cluster \
  --service ll-staging-api --task-definition "$PREV" --force-new-deployment >/dev/null
echo "rollback_started taskdef=${PREV}"
echo "Verify: curl -s http://\$(cd infra/environments/staging && terraform output -raw alb_dns_name)/ready"
