#!/usr/bin/env bash
# Build (optional), push immutable tag, deploy ECS service pinned to digest.
# Usage: deploy_env.sh <staging|production> <image_tag> [--skip-build]
set -euo pipefail

ENV_NAME="${1:?usage: deploy_env.sh <staging|production> <image_tag> [--skip-build]}"
IMAGE_TAG="${2:?image_tag required}"
SKIP_BUILD=0
if [[ "${3:-}" == "--skip-build" ]]; then
  SKIP_BUILD=1
fi

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

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  docker build --platform linux/amd64 -t "${ECR}:${IMAGE_TAG}" -t "${ECR}:latest" ./app
  docker push "${ECR}:${IMAGE_TAG}"
  docker push "${ECR}:latest"
fi

DIGEST=$(aws ecr describe-images --region "$REGION" --repository-name "$ECR_REPO" \
  --image-ids imageTag="${IMAGE_TAG}" --query 'imageDetails[0].imageDigest' --output text)
if [[ -z "$DIGEST" || "$DIGEST" == "None" ]]; then
  echo "ERROR: image tag ${IMAGE_TAG} not found in ${ECR_REPO}"
  exit 1
fi
echo "deploying ${ECR}@${DIGEST} (tag=${IMAGE_TAG} env=${ENV_NAME})"

PREV=$(aws ecs describe-services --region "$REGION" --cluster "$CLUSTER" \
  --services "$SERVICE" --query 'services[0].taskDefinition' --output text)
echo "$PREV" > ".last-taskdef-${ENV_NAME}"
echo "previous_taskdef=${PREV}"

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
echo "deployed_taskdef=${NEW_ARN}"
echo "image_tag=${IMAGE_TAG}"
echo "Rollout uses ECS rolling deploy + deployment circuit breaker rollback."
