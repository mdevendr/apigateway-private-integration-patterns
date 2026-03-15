resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${local.name}-vpclink"
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = aws_subnet.public[*].id

  tags = {
    Name = "${local.name}-vpclink"
  }
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "private_alb" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.this.id
  integration_uri        = aws_lb_listener.alb_http.arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_integration" "direct_lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.backend.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.private_alb.id}"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.private_alb.id}"
}

resource "aws_apigatewayv2_route" "direct_root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /direct"
  target    = "integrations/${aws_apigatewayv2_integration.direct_lambda.id}"
}

resource "aws_apigatewayv2_route" "direct_proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /direct/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.direct_lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationError   = "$context.integrationErrorMessage"
      integrationStatus  = "$context.integration.integrationStatus"
      integrationLatency = "$context.integration.latency"
    })
  }
}