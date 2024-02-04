variable "random_api_name_hex" {
  description = "Randomized part for NAME of API Gateway"
}

variable "random_path_hex" {
  description = "Randomized part for API Gateway Webhook URL"
}

variable "function_invoke_arn" {
  description = "ARN of Lambda function to invoke"
}

variable "get_function_name" {
  description = "Get ARN of Lambda function"
}
