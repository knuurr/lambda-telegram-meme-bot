# variables.tf

variable "aws_profile" {
  description = "AWS profile to use for deployment"
  default     = "default"  # Default profile if not specified in tfvars
}

variable "aws_region" {
  description = "AWS region to use for deployment"
  default     = "eu-central-1"  # Default profile if not specified in tfvars
}

variable "function_name" {
  description = "Name of the Lambda function"
  type = string
}

variable "runtime" {
  description = "Python runtime for the Lambda function"
  default = "python3.10"
  type = string
}

variable "telegram_bot_token" {
  type = string
	sensitive = true
  description = "Telegram Bot Token"
}

variable "run_dependency_script" {
  type = bool
  description = "Control installing Python dependencies for Function. Required for initial deployment, can skip later"
}

# S3 Buckets

variable "s3_bucket_project1" {
  description = "S3 Bucket for Command 1"
  type = string
}

variable "s3_bucket_project2" {
  description = "S3 Bucket for Command 2"
  type = string
}