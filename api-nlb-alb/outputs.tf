
output "api_invoke_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "lambda_name" {
  value = aws_lambda_function.backend.function_name
}
