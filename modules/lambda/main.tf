data "archive_file" "lambda_code_archive" {
  type        = "zip"
  source_dir  = "${path.root}/function_code"
  output_path = "${path.root}/lambda_code.zip"
}


resource "aws_lambda_function" "meme_func" {
  function_name    = var.function_name
  runtime          = var.runtime
  # The handler attribute usually follows the format file_name.method_name
  handler          = "handler.lambda_handler" # Path and filename of the handler file
  role             = var.iam_role_arn
  
  # filename         = "function_code"  # include the function_code directory
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256("${var.lambda_zip_path}")  # Hash for handler.py

  # Timeout in seconds
  timeout = 10
  memory_size   = 256

  environment {
    variables = {
      # Telegram token from Botfather
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token
      # Webhook for automatic registration with Telegram
      AWS_WEBHOOK_URL = var.full_webhook_url
    }
  }
}



# Automatic Telegram Webhook setup upon deploy
data "aws_lambda_invocation" "set_webhook" {
  function_name = aws_lambda_function.meme_func.function_name
  input = <<JSON
{
	"setWebhook": true
}
JSON
}


