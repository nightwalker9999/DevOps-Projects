locals {
  tags = {
    project = var.project
    owner   = "arjun"
    env     = "dev"
  }
}

module "artifacts_bucket" {
  source = "../../modules/s3_bucket"
  name   = var.artifacts_bucket
  tags   = local.tags
}

module "logs_bucket" {
  source = "../../modules/s3_bucket"
  name   = var.logs_bucket
  tags   = local.tags
}

module "queue" {
  source                  = "../../modules/sqs_queue"
  name                    = var.queue_name
  dlq_name                = "${var.queue_name}-dlq"
  message_retention_secs  = 1209600 # 14 days
  visibility_timeout_secs = 30
  tags                    = local.tags
}

module "sns_topic_notifications" {
  source = "../../modules/sns_topic"
  name   = "arjun_notify"
  tags   = local.tags
}

module "cw_logs_group" {
  source            = "../../modules/cw_logs_group"
  name              = "/arjun/app"
  retention_in_days = 7
  tags              = local.tags
}

# Allow SNS to send to our SQS queue
# Need to read about it. What is this policy and sqs ?

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = module.queue.queue_url
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowSNSSendMessage",
      Effect    = "Allow",
      Principal = { Service = "sns.amazonaws.com" },
      Action    = "SQS:SendMessage",
      Resource  = module.queue.queue_arn,
      Condition = { ArnEquals = { "aws:SourceArn" = module.sns_topic_notifications.sns_topic_arn } }
    }]
  })
}

# Subscribe SQS to the SNS sns_topic
# Need to understand why we added the policy resource. What is policy? What is arn? What is topic? What is queue here?
resource "aws_sns_topic_subscription" "to_queue" {
  topic_arn            = module.sns_topic_notifications.sns_topic_arn
  protocol             = "sqs"
  endpoint             = module.queue.queue_arn
  raw_message_delivery = true
}
