output "sns_topic_arn" {
  # what is arn ? Check that
  value = aws_sns_topic.sns_topic.arn
}