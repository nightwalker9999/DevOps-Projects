#!/usr/bin/env bash
set -euo pipefail

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-test}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-test}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
AWSEND=${AWS_ENDPOINT_URL:-http://localhost:4566}
alias awslocal="aws --endpoint-url $AWSEND"

TOPIC_NAME=${TOPIC_NAME:-arjun_notify}
QUEUE_NAME=${QUEUE_NAME:-arjun-main-queue}

echo "==> Creating SNS topic: $TOPIC_NAME"
TOPIC_ARN=$(awslocal sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)
echo "TOPIC_ARN=$TOPIC_ARN"

echo "==> Creating SQS queue: $QUEUE_NAME"
awslocal sqs create-queue --queue-name "$QUEUE_NAME" >/dev/null 2>&1 || true
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name "$QUEUE_NAME" --query 'QueueUrl' --output text)
QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
echo "QUEUE_URL=$QUEUE_URL"
echo "QUEUE_ARN=$QUEUE_ARN"

echo "==> Attaching queue policy to allow SNS -> SQS"
cat > /tmp/sqs-attrs.json <<EOF
{
  "Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowSNSToSend\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"$QUEUE_ARN\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":\"$TOPIC_ARN\"}}}]}"
}
EOF
awslocal sqs set-queue-attributes --queue-url "$QUEUE_URL" --attributes file:///tmp/sqs-attrs.json

echo "==> Subscribing queue to topic"
awslocal sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$QUEUE_ARN" --attributes RawMessageDelivery=true >/dev/null

echo "==> Done."
echo "export TOPIC_ARN=$TOPIC_ARN"
echo "export QUEUE_URL=$QUEUE_URL"
echo "export QUEUE_ARN=$QUEUE_ARN"