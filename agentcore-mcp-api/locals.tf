resource "local_file" "agentcore_target_config" {
  filename        = "${path.module}/.agentcore-target-config.json"
  content         = jsonencode(local.target_configuration)
  file_permission = "0644"
}

resource "local_file" "agentcore_target_creds" {
  filename        = "${path.module}/.agentcore-target-creds.json"
  content         = jsonencode([])
  file_permission = "0644"
}

locals {
  target_configuration = {
    mcp = {
      apiGateway = {
        restApiId = var.rest_api_id
        stage     = var.rest_api_stage
        apiGatewayToolConfiguration = {
          toolFilters = [
            for tf in var.tool_filters : {
              filterPath = tf.filter_path
              methods    = tf.methods
            }
          ]
          toolOverrides = [
            for to in var.tool_overrides : {
              name        = to.name
              description = to.description
              method      = to.method
              path        = to.path
            }
          ]
        }
      }
    }
  }
}
