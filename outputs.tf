# URL related

output "function_name" {
  description = "Name of the Lambda function."
  value = module.lambda.function_name
}

output "api_name" {
  description = "Name of API Gateway"
  value = module.api-gateway-v2.get_api_gw_name
}

output "lambda_function_webhook" {
  description = "Full API Gateway Webhook URL"
  value = "${module.api-gateway-v2.get_api_gw_url_endpoint}/${random_id.random_path.hex}/"
}

# Cloudwatch Logs

output "get_cloudwatch_logs_group_name" {
  description = "Get CloudWatch Log Group Name associated with Function"
  value = module.cloudwatch_logs.cloudwatch_logs_group_name
}


