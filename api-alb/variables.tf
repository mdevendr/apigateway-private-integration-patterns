variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "api-vpcl-alb"
}