#!/usr/bin/env bash
set -euo pipefail

# Ensure LocalStack is running and awslocal is available
command -v awslocal >/dev/null 2>&1 || { echo >&2 "awslocal not found. Install 'awscli-local' (pipx install awscli-local)."; exit 1; }

# Wait for LocalStack edge port
echo "Waiting for LocalStack (http://localhost:4566) ..."
for i in {1..30}; do
  if nc -z localhost 4566 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-test}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-test}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

STATE_BUCKET="${STATE_BUCKET:-tfstate-arjun}"
LOCK_TABLE="${LOCK_TABLE:-tfstate-locks}"

echo "Creating S3 bucket: ${STATE_BUCKET}"
awslocal s3 mb "s3://${STATE_BUCKET}" || true
awslocal s3api put-bucket-versioning --bucket "${STATE_BUCKET}" --versioning-configuration Status=Enabled || true

echo "Creating DynamoDB lock table: ${LOCK_TABLE}"
awslocal dynamodb create-table   --table-name "${LOCK_TABLE}"   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST || true

echo "Bootstrap complete."
