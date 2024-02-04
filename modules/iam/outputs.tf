# modules/iam/outputs.tf

# Output the ARN of the IAM role
output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}
