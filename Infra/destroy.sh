#!/usr/bin/env bash
#
# Completely tear down the S3 Event-Driven Architecture demo.
#
# CloudFormation cannot delete a non-empty S3 bucket, so this script first
# empties the bucket (all objects AND versions / delete markers), then deletes
# the stack and waits for the deletion to finish.
#
# Usage:
#   ./destroy.sh
#   PROJECT_NAME=my-demo STACK_NAME=my-stack REGION=us-east-1 ./destroy.sh
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-s3-event-demo}"
STACK_NAME="${STACK_NAME:-${PROJECT_NAME}}"
REGION="${REGION:-$(aws configure get region 2>/dev/null || echo us-east-1)}"

echo "Tearing down stack '${STACK_NAME}' in region '${REGION}'..."

# 1. Resolve the bucket name from the stack output (not hardcoded).
BUCKET_NAME="$(aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue | [0]" \
  --output text 2>/dev/null || echo "")"

# 2. Empty the bucket if it exists.
if [[ -n "${BUCKET_NAME}" && "${BUCKET_NAME}" != "None" ]]; then
  if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
    echo "Emptying bucket '${BUCKET_NAME}'..."
    # Remove current objects.
    aws s3 rm "s3://${BUCKET_NAME}" --recursive --region "${REGION}" || true

    # Remove any object versions and delete markers (in case versioning was on).
    VERSIONS="$(aws s3api list-object-versions \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null || echo '{"Objects":null}')"
    if [[ "$(echo "${VERSIONS}" | tr -d '[:space:]')" != '{"Objects":null}' ]]; then
      aws s3api delete-objects --bucket "${BUCKET_NAME}" --region "${REGION}" \
        --delete "${VERSIONS}" >/dev/null 2>&1 || true
    fi

    MARKERS="$(aws s3api list-object-versions \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null || echo '{"Objects":null}')"
    if [[ "$(echo "${MARKERS}" | tr -d '[:space:]')" != '{"Objects":null}' ]]; then
      aws s3api delete-objects --bucket "${BUCKET_NAME}" --region "${REGION}" \
        --delete "${MARKERS}" >/dev/null 2>&1 || true
    fi
  else
    echo "Bucket '${BUCKET_NAME}' not found - skipping empty step."
  fi
else
  echo "No BucketName output found - skipping empty step."
fi

# 3. Delete the stack and wait.
echo "Deleting stack '${STACK_NAME}'..."
aws cloudformation delete-stack --stack-name "${STACK_NAME}" --region "${REGION}"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}" --region "${REGION}"

echo "Teardown complete. All resources for '${STACK_NAME}' have been removed."
