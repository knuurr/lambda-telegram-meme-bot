terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.35.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}


resource "random_id" "random_path" {
	byte_length = 16
}

resource "random_id" "id" {
  byte_length = 8
}

# Set IAM roles for Lambda
module "iam" {
  source = "./modules/iam"
  # Required for bucket permissions
  s3_bucket_name1 = var.s3_bucket_project1
  s3_bucket_name2 = var.s3_bucket_project2
  function_name = "${random_id.id.hex}-function-${var.function_name}"
}

# Setup API Gateway for Webhook
module "api-gateway-v2" {
  source = "./modules/api-gateway-v2"
  random_api_name_hex =  "${random_id.id.hex}"
  random_path_hex = "${random_id.random_path.hex}"
  get_function_name = module.lambda.get_arn
  function_invoke_arn = module.lambda.get_invoke_arn
}

# Setup Lambda function 
module "lambda" {
  source        = "./modules/lambda"
  function_name = "${random_id.id.hex}-function-${var.function_name}"
  runtime       = var.runtime
  iam_role_arn  = "${module.iam.lambda_role_arn}"
  lambda_zip_path = data.archive_file.lambda_code_archive.output_path
  # Tegeram token
  telegram_bot_token = var.telegram_bot_token
  # AWS endpointfull  URL - for token autosetup
  full_webhook_url = "${module.api-gateway-v2.get_api_gw_url_endpoint}/${random_id.random_path.hex}/"
}

module "cloudwatch_logs" {
  source          = "./modules/cw-logs"
  log_group_name  = "/aws/lambda/${random_id.id.hex}-function-${var.function_name}"
  retention_days  = 30
}


# generate ZIP file with deployment for Lambda

data "archive_file" "lambda_code_archive" {
  # Declare a dependency between null_resource and data block
  depends_on  = [null_resource.generate_package]
  type        = "zip"
  # Zip together handler along with Python deps, other stuff too if needed
  source_dir  = "${path.root}/function_code"
  output_path = "${path.root}/lambda_code.zip"
}


# Run local script to generate "package" folder with Python deps
resource "null_resource" "generate_package" {
  count = var.run_dependency_script ? 1 : 0  # Conditional execution based on variable

  triggers = {
    always_run = timestamp()
  }
  # Run local script
  provisioner "local-exec" {
    command = "${path.root}/install_dependencies.sh"
    
  }
}
