output "cw_logs_group_arn" {
  value = aws_cloudwatch_log_group.cw_logs_group.name
}