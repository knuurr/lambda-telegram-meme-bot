# Telegram Bot on AWS Lambda with Terraform Deployment

Welcome to the Telegram Bot deployment project! 

This project allows you to set up your own 
Telegram bot hosted on AWS Lambda, with the ability to retrieve random images from S3 buckets and return random one-liners from a stored text file. The bot is perfect for sharing memes and easy access if reaction images accumulated over time.

# Pre-requisites
Before deploying the bot, ensure you have the following:

- **AWS Account**: You need an AWS account to deploy the bot using Lambda and S3.
- **Telegram Account**: Obtain a Telegram account and create a new bot using BotFather. This tutorial assumes basic familiarity with setting up a Telegram bot. If you're unfamiliar with this process, refer to online tutorials for guidance.
- **At least one S3 bucket**: For fetching images, bot required S3 bucket created, with some images on root of bucket. This is currently handled outside of this stack.


Also in any case, remember to remove `*.example` suffixes.

# Function preparation

Everything that's inside `function_code` folder will end up together with function in single zip.

Function relies on `function_code/config.yml` (example present in folder). In short, this config is parsed during function runtime and checked for all possible incoming Telegram commands to handle. Eahc command is bound to location of either text file or S3 bucket for images to fetch from.

As example, You'll find an example `config.yml` file within that folder. If you wish to check how it works on example,, move `toasts.txt` file from project root to `function_code` folder before deployment and register `/toast` function for your bot from the app itself.


# Deployment Steps

Follow these steps to deploy your Telegram bot:

1. Clone the repository and navigate to project directory


2. Install required Python dependencies to targte folder


This function relies on few packages in order to work properly.

You can either execute the `install_dependencies.sh` script to install necessary Python dependencies for AWS Lambda to `function_code/package` location (which will be zipped together with handler) 

You can also automate this step by supplying `-var="run_dependency_script=true"` to the Terraform command during deployment, or changing value within `env/*.tfvars` files.

This step is required especially before first initial deployment of function. Once fetched, you don't need to do this again unless dependency folder has been removed or you wish to update/reinstall dependencies.

Script provisioning is handled locally using `null_resource` from `main.tf`.


```hcl
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

```


3. Set the required variables in `env/*.tfvars` per your configuration. You can utilize a file per environment i.e `dev`, `prod`.

There you can set function name, Telegram bot token and S3 bucket to fetch from.

Important is to provide names of S3 buckets in here (this is currently handled outside of this stack) which is needed to ensure proper permissions for them.

```hcl
# Needed for permission setting
s3_bucket_project1      = "bucket-project-two"
s3_bucket_project2    = "bucket-project-one"
```


4. Deploy the bot using Terraform


```bash
# With script, for first deploy
terraform init
terraform plan -var="run_dependency_script=true" -var-file=env/prod.tfvars
terraform apply -var="run_dependency_script=true" -var-file=env/prod.tfvars

# Without script
terraform init
terraform plan -var-file=env/prod.tfvars
terraform apply -var-file=env/prod.tfvars
```


If everything went OK, in terminal You'll see some outputs, including your webhook URL

```text
Apply complete! Resources: 5 added, 1 changed, 5 destroyed.

Outputs:

api_name = "api-xxxxxxxxxx"
function_name = "xxxxxxxxxxxx-function-name"
get_cloudwatch_logs_group_name = "/aws/lambda/xxxxxxxxxxxxxxxxxxxx"
lambda_function_webhook = "https://xxxxxxxxxxxxxxxxxxxx.eu-central-1.amazonaws.com/randomstring/"
```


Thanks to clever integration within terraform and supplied Telegram bot token, Your AWS API URL should automatically associated with your Telegram bot:

```hcl
# Automatic Telegram Webhook setup upon deploy
data "aws_lambda_invocation" "set_webhook" {
  function_name = aws_lambda_function.meme_func.function_name
  input = <<JSON
{
	"setWebhook": true
}
JSON
}
```

If this was not the case, you can manually bind URL to Telegram bot i.e. from browser.

Substitute `{bot_token}` with your actual token (omit braces) and as `?url=` parameter supply AWS URL from output:

```bash
https://api.telegram.org/bot{bot_token}/setWebhook?url=https://xxxxxxxxxxxxxxxxxxxx.eu-central-1.amazonaws.com/randomstring/


https://api.telegram.org/botxxxxxxxxxxxxxxxxxxx::yyyyyyyyyyyyyyyy/setWebhook?url=https://xxxxxxxxxxxxxxxxxxxx.eu-central-1.amazonaws.com/randomstring/

```

# Test commands

Various commands to debug after `terraform apply` (as they rely on outputs)

inspect the contents of the S3 bucket.

```bash
aws s3 ls $(terraform output -raw lambda_bucket_name)
```

Test function output

```bash
aws lambda invoke --region=eu-central-1 --function-name=$(terraform output -raw function_name) response.json
```

Test function inpout, with prepared JSON payload

```bash
aws lambda invoke --region=eu-central-1 --function-name=$(terraform output -raw function_name) --payload file://path/to/your/input.json response.json
```

Listing CloudWatch Logs Groups:

```bash
aws logs describe-log-groups --region=eu-central-1
```

Listing CloudWatch Logs for Deployed function:

```bash
aws logs describe-log-streams --log-group-name=$(terraform output -raw get_cloudwatch_logs_group_name) --region=eu-central-1
```

# Ideas/issues

- In it's current form, function does not have support for S3 paths. Rather than having multiple buckets, single bucket with per-command routing based on path would be way better than easier, but I couldn't find good implementation example for `boto3`
- Text files could too be fetched from S3 instead of kept in function filesystem directly. That's yet to be implemented
- There might be issue with capturing logs using Cloudwatch
- Deployment of S3 bucket could too be handled from this stack

# Sources

- https://spacelift.io/blog/terraform-api-gateway
- https://leejjon.medium.com/use-terraform-to-create-an-aws-lambda-function-that-runs-your-typescript-code-b805db667a93
- https://stackoverflow.com/questions/54277401/how-to-pass-outputs-from-one-module-to-another
- https://advancedweb.hu/deploy-a-serverless-telegram-bot-to-aws-using-terraform/

