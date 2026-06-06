#!/usr/bin/env bash
#
# Deploy the S3 Event-Driven Architecture demo stack.
#
# Usage:
#   ./deploy.sh
#   PROJECT_NAME=my-demo STACK_NAME=my-stack REGION=us-east-1 ./deploy.sh
#
# All names are derived from PROJECT_NAME - nothing is hardcoded.
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-s3-event-demo}"
STACK_NAME="${STACK_NAME:-${PROJECT_NAME}}"
REGION="${REGION:-$(aws configure get region 2>/dev/null || echo us-east-1)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/s3-event-demo.yaml"

echo "Deploying stack '${STACK_NAME}' (project '${PROJECT_NAME}') to region '${REGION}'..."

aws cloudformation deploy \
  --template-file "${TEMPLATE_FILE}" \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ProjectName=${PROJECT_NAME}"

echo ""
echo "Stack outputs:"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' \
  --output table
