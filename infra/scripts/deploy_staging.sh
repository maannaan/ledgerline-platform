#!/usr/bin/env bash
# Build, push immutable digest, roll ECS service. Zero-downtime via ECS rolling + circuit breaker.
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/ll-staging-api"
TAG="${GIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo manual)}"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

docker build --platform linux/amd64 -t "${ECR}:${TAG}" -t "${ECR}:latest" ./app
docker push "${ECR}:${TAG}"
docker push "${ECR}:latest"
DIGEST=$(aws ecr describe-images --region "$REGION" --repository-name ll-staging-api \
  --image-ids imageTag="${TAG}" --query 'imageDetails[0].imageDigest' --output text)
echo "deploying ${ECR}@${DIGEST}"

# Record previous task def for rollback
PREV=$(aws ecs describe-services --region "$REGION" --cluster ll-staging-cluster \
  --services ll-staging-api --query 'services[0].taskDefinition' --output text)
echo "$PREV" > ".last-taskdef-staging"
echo "previous_taskdef=${PREV}"

# Register new task def revision with digest-pinned image
TASK_JSON=$(aws ecs describe-task-definition --region "$REGION" --task-definition ll-staging-api \
  --query 'taskDefinition' --output json)
NEW_TD=$(python3 - "$TASK_JSON" "${ECR}@${DIGEST}" <<'PY'
import json,sys
td=json.loads(sys.argv[1])
image=sys.argv[2]
for c in td["containerDefinitions"]:
    if c["name"]=="api":
        c["image"]=image
keep=["family","taskRoleArn","executionRoleArn","networkMode","containerDefinitions",
      "requiresCompatibilities","cpu","memory"]
out={k:td[k] for k in keep if k in td}
print(json.dumps(out))
PY
)
NEW_ARN=$(aws ecs register-task-definition --region "$REGION" --cli-input-json "$NEW_TD" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

aws ecs update-service --region "$REGION" --cluster ll-staging-cluster \
  --service ll-staging-api --task-definition "$NEW_ARN" --force-new-deployment >/dev/null
echo "deployed_taskdef=${NEW_ARN}"
echo "Rollout uses ECS rolling deploy + deployment circuit breaker rollback."
