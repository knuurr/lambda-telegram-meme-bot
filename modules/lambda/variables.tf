variable "function_name" {
  description = "Name of the Lambda function"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
}

variable "telegram_bot_token" {
  description = "Telegram Bot Token"
}

variable "iam_role_arn" {
  description = "IAM role ARN for Lambda function"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket"
}

variable "full_webhook_url" {
  description = "Full URL for AWS Webhook - for Telegram auto-bind"
}


