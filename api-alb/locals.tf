locals {
  name = var.name_prefix
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}
