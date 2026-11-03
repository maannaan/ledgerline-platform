#!/usr/bin/env bash
# Create SNS topic, 3 alarms, and CloudWatch dashboard for staging.
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"
EMAIL="${BUDGET_EMAIL:-mananpaliwal30@gmail.com}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

LB_ARN=$(aws elbv2 describe-load-balancers --region "$REGION" --names ll-staging-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LB_FULL=${LB_ARN#*:loadbalancer/}
TG_ARN=$(aws elbv2 describe-target-groups --region "$REGION" --names ll-staging-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
TG_FULL="targetgroup/${TG_ARN##*targetgroup/}"

TOPIC_ARN=$(aws sns create-topic --region "$REGION" --name ledgerline-staging-alerts \
  --query TopicArn --output text)
aws sns subscribe --region "$REGION" --topic-arn "$TOPIC_ARN" --protocol email \
  --notification-endpoint "$EMAIL" >/dev/null || true

aws cloudwatch put-metric-alarm --region "$REGION" \
  --alarm-name ledgerline-staging-5xx \
  --alarm-description "SLO availability: elevated target 5xx" \
  --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value="$LB_FULL" \
  --statistic Sum --period 60 --evaluation-periods 5 --threshold 5 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --region "$REGION" \
  --alarm-name ledgerline-staging-latency \
  --alarm-description "SLO latency: TargetResponseTime average > 300ms" \
  --namespace AWS/ApplicationELB --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value="$LB_FULL" \
  --statistic Average --period 60 --evaluation-periods 10 --threshold 0.3 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --region "$REGION" \
  --alarm-name ledgerline-staging-unhealthy-hosts \
  --alarm-description "Dependency/task health: unhealthy hosts > 0" \
  --namespace AWS/ApplicationELB --metric-name UnHealthyHostCount \
  --dimensions Name=TargetGroup,Value="$TG_FULL" Name=LoadBalancer,Value="$LB_FULL" \
  --statistic Maximum --period 60 --evaluation-periods 5 --threshold 0 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

python3 - "$ROOT/observability/dashboards/ledgerline-staging.json" "$LB_FULL" "$TG_FULL" <<'PY' > /tmp/cw-dash.json
import json,sys
body=json.load(open(sys.argv[1]))
raw=json.dumps(body)
raw=raw.replace("REPLACE_LB", sys.argv[2]).replace("REPLACE_TG", sys.argv[3])
print(raw)
PY

aws cloudwatch put-dashboard --region "$REGION" \
  --dashboard-name Ledgerline-Staging \
  --dashboard-body file:///tmp/cw-dash.json

{
  echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "dashboard=Ledgerline-Staging"
  echo "sns_topic=$TOPIC_ARN"
  echo "alarms=ledgerline-staging-5xx,ledgerline-staging-latency,ledgerline-staging-unhealthy-hosts"
  echo "lb=$LB_FULL"
  echo "tg=$TG_FULL"
} | tee "$ROOT/docs/evidence/phase4/cloudwatch-apply.txt"

echo "Confirm SNS email subscription in $EMAIL inbox."
