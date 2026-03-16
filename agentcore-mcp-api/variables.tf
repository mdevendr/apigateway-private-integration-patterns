variable "aws_region" {
  description = "AWS Region for AgentCore Gateway and the existing REST API. They must be in the same Region."
  type        = string
}

variable "gateway_name" {
  description = "Name of the AgentCore gateway."
  type        = string
}

variable "gateway_description" {
  description = "Description of the AgentCore gateway."
  type        = string
  default     = "AgentCore MCP gateway for an existing API Gateway REST API"
}

variable "gateway_role_name" {
  description = "IAM role name used by AgentCore Gateway."
  type        = string
}

variable "gateway_authorizer_type" {
  description = "Inbound auth for the AgentCore gateway. Use NONE for the quickest demo, or AWS_IAM if your client will sign InvokeGateway requests."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AWS_IAM"], var.gateway_authorizer_type)
    error_message = "gateway_authorizer_type must be NONE or AWS_IAM."
  }
}

variable "target_name" {
  description = "Name of the AgentCore gateway target."
  type        = string
}

variable "target_description" {
  description = "Description of the AgentCore gateway target."
  type        = string
  default     = "API Gateway REST API target"
}

variable "rest_api_id" {
  description = "Existing API Gateway REST API ID to expose through AgentCore."
  type        = string
}

variable "rest_api_stage" {
  description = "Existing deployed stage name on the REST API."
  type        = string
  default    = "demo"
}

variable "target_outbound_auth" {
  description = "How AgentCore calls the REST API target. Use NO_AUTH for a public unauthenticated REST API, or GATEWAY_IAM_ROLE when API methods use AWS_IAM."
  type        = string
  default     = "NO_AUTH"

  validation {
    condition     = contains(["NO_AUTH", "GATEWAY_IAM_ROLE"], var.target_outbound_auth)
    error_message = "target_outbound_auth must be NO_AUTH or GATEWAY_IAM_ROLE."
  }
}

variable "tool_filters" {
  description = "Allow-list of REST API operations to expose as MCP tools. filter_path supports exact paths or wildcards like /pets/*."
  type = list(object({
    filter_path = string
    methods     = list(string)
  }))
}

variable "tool_overrides" {
  description = "Optional explicit tool names and descriptions. Use this when your exported API lacks operationId values or you want nicer tool names."
  type = list(object({
    path        = string
    method      = string
    name        = string
    description = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to Terraform-managed AWS resources."
  type        = map(string)
  default     = {}
}
