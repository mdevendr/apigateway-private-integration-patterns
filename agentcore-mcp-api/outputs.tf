output "agentcore_gateway_id" {
  description = "AgentCore gateway ID."
  value       = aws_bedrockagentcore_gateway.this.gateway_id
}

output "agentcore_gateway_arn" {
  description = "AgentCore gateway ARN."
  value       = aws_bedrockagentcore_gateway.this.gateway_arn
}

output "agentcore_gateway_url" {
  description = "MCP endpoint URL for the AgentCore gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_url
}

output "agentcore_gateway_role_arn" {
  description = "IAM role ARN used by AgentCore Gateway."
  value       = aws_iam_role.agentcore_gateway.arn
}

output "rest_api_target_summary" {
  description = "Summary of the REST API target configuration pushed through the AWS CLI."
  value = {
    rest_api_id          = var.rest_api_id
    rest_api_stage       = var.rest_api_stage
    target_name          = var.target_name
    target_outbound_auth = var.target_outbound_auth
    tool_filters         = var.tool_filters
    tool_overrides       = var.tool_overrides
  }
}

output "agentcore_target_result_file" {
  description = "Local file written by the CLI create/update step. It contains the returned target details, including targetId."
  value       = "${path.module}/.agentcore-target-result.json"
}
