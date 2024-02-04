output "get_api_gw_name" {
  description = "Name of API Gateway"
  value = aws_apigatewayv2_api.api.name
}


output "get_api_gw_url_endpoint" {
    description = "API Gateway URL endpoint"
    value = aws_apigatewayv2_api.api.api_endpoint
}