resource "aws_apigatewayv2_api" "api" {
	name          = "api-${var.random_api_name_hex}"
	protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
	api_id           = aws_apigatewayv2_api.api.id
	integration_type = "AWS_PROXY"

	integration_method     = "POST"
	integration_uri        = var.function_invoke_arn
	payload_format_version = "2.0"
}

# Genrate route key and a random ID
# As a result, every request that does not include this random path will be rejected by the API Gateway.

resource "aws_apigatewayv2_route" "api" {
	api_id    = aws_apigatewayv2_api.api.id
	route_key     = "ANY /${var.random_path_hex}/{proxy+}"

	target = "integrations/${aws_apigatewayv2_integration.api.id}"
}



resource "aws_apigatewayv2_stage" "api" {
	api_id      = aws_apigatewayv2_api.api.id
	name        = "$default"
	auto_deploy = true
}

# give permission to call the lambda
resource "aws_lambda_permission" "apigw" {
	action        = "lambda:InvokeFunction"
	function_name = var.get_function_name
	principal     = "apigateway.amazonaws.com"

	source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

