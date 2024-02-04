# modules/lambda/outputs.tf

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value = aws_lambda_function.meme_func.arn
}

# output "lambda_function_invoke_url" {
#   value = aws_lambda_function.meme_func.lambda_function_invoke_url
# }

output "lambda_function_code_path" {
  value = aws_lambda_function.meme_func.filename
}


output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.meme_func.function_name
}

output "get_invoke_arn" {
  description = "Get Invoke ARN."

  value = aws_lambda_function.meme_func.invoke_arn
}

output "get_arn" {
  description = "Get ARN."

  value = aws_lambda_function.meme_func.arn
}

