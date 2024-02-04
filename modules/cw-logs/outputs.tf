
output "cloudwatch_logs_group_name" {
  description = "CloudWatch Log Group Name"
  value = aws_cloudwatch_log_group.log_group.name
}


output "cloudwatch_logs_group_arn" {
  description = "CloudWatch Log Group ARN"
  value = aws_cloudwatch_log_group.log_group.arn
}


