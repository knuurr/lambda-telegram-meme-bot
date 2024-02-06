# data "archive_file" "lambda_code_archive" {
#   type        = "zip"
#   source_dir  = "${path.root}/function_code"
#   output_path = "${path.root}/lambda_code.zip"
# }


resource "aws_lambda_function" "meme_func" {
  function_name    = var.function_name
  runtime          = var.runtime
  # The handler attribute usually follows the format file_name.method_name
  handler          = "handler.lambda_handler" # Path and filename of the handler file
  role             = var.iam_role_arn
  
  # filename         = "function_code"  # include the function_code directory
  filename         = data.archive_file.lambda_code_archive.output_path
  source_code_hash = filebase64sha256("${path.root}/function_code/handler.py")  # Hash for handler.py

  # Dependencies layer
  layers = [ aws_lambda_layer_version.dependencies_layer.arn ]

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


# Run local script to generate "package" folder with Python deps
resource "null_resource" "generate_dependencies_layer" {
  triggers = {
    # Trigger when requirements.txt changes or the dependencies zip is unavailable
    # requirements    = filesha1("${path.root}/requirements.txt")
    requirements_txt_sha = filemd5("${path.root}/requirements.txt")
    zip_file_exists      = fileexists("${path.root}/dependencies.zip") ? "1" : "0"

    # zip_unavailable =  ("${path.root}/dependencies.zip") == ""
  }

  # Run local script
  provisioner "local-exec" {
    # command = "${path.root}/install_dependencies.sh"
    command = "pip install -r ${path.root}/requirements.txt -t ${path.root}/package/python"
  }
}


# Deploy ZIP layer for runtime dependencies
resource "aws_lambda_layer_version" "dependencies_layer" {
  layer_name = "${var.function_name}-deps-layer"
  compatible_runtimes = [var.runtime]

  # Specify the path to your dependencies
  # source_code_hash = filebase64sha256("${path.root}/requirements.txt")
  filename         = "${path.root}/dependencies.zip"
  depends_on = [ data.archive_file.lambda_deps_archive ]
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

# generate ZIP file with dependencies-only deployment for Lambda
data "archive_file" "lambda_deps_archive" {
  # Declare a dependency between null_resource and data block
  # depends_on  = [null_resource.generate_package]
  type        = "zip"
  # Zip together handler along with Python deps, other stuff too if needed
  source_dir  = "${path.root}/package"
  output_path = "${path.root}/dependencies.zip"
  depends_on = [ null_resource.generate_dependencies_layer ]
}




# generate ZIP file with handler deployment for Lambda
data "archive_file" "lambda_code_archive" {
  # Declare a dependency between null_resource and data block
  # depends_on  = [null_resource.generate_package]
  type        = "zip"
  # Zip together handler along with Python deps, other stuff too if needed
  source_dir  = "${path.root}/function_code"
  output_path = "${path.root}/lambda_code.zip"
}


