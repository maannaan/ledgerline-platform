#!/usr/bin/env bash
# Rollback by redeploying an existing ECR image tag (digest-pinned task def).
# Usage: rollback_env.sh <staging|production> <image_tag>
set -euo pipefail

ENV_NAME="${1:?usage: rollback_env.sh <staging|production> <image_tag>}"
IMAGE_TAG="${2:?image_tag required (known-good ECR tag)}"

case "$ENV_NAME" in
  staging|production) ;;
  *) echo "ENV must be staging|production"; exit 1 ;;
esac

REGION="${AWS_REGION:-ap-south-1}"
PREFIX="ll-${ENV_NAME}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${PREFIX}-api"
ECR="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"
CLUSTER="${PREFIX}-cluster"
SERVICE="${PREFIX}-api"
TASK_FAMILY="${PREFIX}-api"

DIGEST=$(aws ecr describe-images --region "$REGION" --repository-name "$ECR_REPO" \
  --image-ids imageTag="${IMAGE_TAG}" --query 'imageDetails[0].imageDigest' --output text)
if [[ -z "$DIGEST" || "$DIGEST" == "None" ]]; then
  echo "ERROR: rollback tag ${IMAGE_TAG} not found in ${ECR_REPO}"
  exit 1
fi
echo "Rolling back ${ENV_NAME} to tag=${IMAGE_TAG} digest=${DIGEST}"

TASK_JSON=$(aws ecs describe-task-definition --region "$REGION" --task-definition "$TASK_FAMILY" \
  --query 'taskDefinition' --output json)
NEW_TD=$(python3 - "$TASK_JSON" "${ECR}@${DIGEST}" <<'PY'
import json, sys
td = json.loads(sys.argv[1])
image = sys.argv[2]
for c in td["containerDefinitions"]:
    if c["name"] == "api":
        c["image"] = image
keep = ["family", "taskRoleArn", "executionRoleArn", "networkMode", "containerDefinitions",
        "requiresCompatibilities", "cpu", "memory"]
out = {k: td[k] for k in keep if k in td}
print(json.dumps(out))
PY
)
NEW_ARN=$(aws ecs register-task-definition --region "$REGION" --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

aws ecs update-service --region "$REGION" --cluster "$CLUSTER" \
  --service "$SERVICE" --task-definition "$NEW_ARN" --force-new-deployment >/dev/null
echo "rollback_started taskdef=${NEW_ARN} image_tag=${IMAGE_TAG}"
echo "Verify /ready on the env ALB after tasks stabilize."
