resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${local.name}-http-api"
  retention_in_days = 7
}