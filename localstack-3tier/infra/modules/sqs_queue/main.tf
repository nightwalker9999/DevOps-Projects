resource "aws_sqs_queue" "dlq" {
  name = var.dlq_name
  tags = var.tags
}

resource "aws_sqs_queue" "main" {
  name                      = var.name
  visibility_timeout_seconds = var.visibility_timeout_secs
  message_retention_seconds  = var.message_retention_secs
  redrive_policy             = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
  tags = var.tags
}
