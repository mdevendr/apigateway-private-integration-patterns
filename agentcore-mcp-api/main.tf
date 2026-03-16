
resource "aws_iam_role" "agentcore_gateway" {
  name = var.gateway_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "agentcore_gateway_invoke_rest_api" {
  count = var.target_outbound_auth == "GATEWAY_IAM_ROLE" ? 1 : 0

  name = "${var.gateway_role_name}-invoke-api"
  role = aws_iam_role.agentcore_gateway.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeRestApiStage"
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/${var.rest_api_stage}/*/*"
        ]
      }
    ]
  })
}

resource "aws_bedrockagentcore_gateway" "this" {
  name            = var.gateway_name
  description     = var.gateway_description
  protocol_type   = "MCP"
  authorizer_type = var.gateway_authorizer_type
  role_arn        = aws_iam_role.agentcore_gateway.arn

  tags = var.tags
}
