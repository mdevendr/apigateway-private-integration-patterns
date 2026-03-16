aws_region        = "eu-west-2"
gateway_name      = "petstore-agentcore-gateway"
gateway_role_name = "petstore-agentcore-gateway-role"

# quickest demo
gateway_authorizer_type = "NONE"

target_name        = "petstore-restapi-target"
target_description = "PetStore REST API target for AgentCore"

rest_api_id    = "wzvhpzmn4b"
rest_api_stage = "demo"


# use NO_AUTH if your REST API methods are public / unauthenticated
# use GATEWAY_IAM_ROLE only if the API methods use AWS_IAM
target_outbound_auth = "NO_AUTH"

tool_filters = [
  {
    filter_path = "/pets"
    methods     = ["GET"]
  },
  {
    filter_path = "/pets/{petId}"
    methods     = ["GET"]
  }
]

tool_overrides = [
  {
    path        = "/pets"
    method      = "GET"
    name        = "listPets"
    description = "List pets from the PetStore API"
  },
  {
    path        = "/pets/{petId}"
    method      = "GET"
    name        = "getPetById"
    description = "Get a pet by ID from the PetStore API"
  }
]

tags = {
  Project = "agentcore-petstore-demo"
}