# AgentCore MCP API Pattern

Expose an existing **AWS API Gateway REST API as MCP tools** using
**Amazon Bedrock AgentCore Gateway**.

This pattern demonstrates how an existing API can be converted into
**AI-callable tools** using the **Model Context Protocol (MCP)** without
modifying the API implementation.

This repository uses the **PetStore demo API** to illustrate the
pattern.

------------------------------------------------------------------------

# Architecture

    AI Agent / MCP Client
            │
            │  MCP protocol
            ▼
    Amazon Bedrock AgentCore Gateway
            │
            │  Target: API Gateway
            ▼
    AWS API Gateway (PetStore REST API)
            │
            ▼
    Backend Service

The **AgentCore Gateway exposes API operations as MCP tools** which can
be invoked by AI agents or MCP clients.

------------------------------------------------------------------------

# Demo Scenario

This repository uses the **AWS PetStore example API**.

Example endpoint:

    GET https://<rest-api-id>.execute-api.<region>.amazonaws.com/demo/pets

Important demo configuration:

  Parameter        Value
  ---------------- -----------
  REST API         PetStore
  Stage            `demo`
  Authentication   `NO_AUTH`
  Region           eu-west-1

The PetStore API is publicly accessible, therefore the AgentCore target
uses:

    NO_AUTH

for outbound authentication.

------------------------------------------------------------------------

# What this repository demonstrates

This repo shows how to:

1.  Deploy an **AgentCore Gateway using Terraform**
2.  Generate the **AgentCore target configuration**
3.  Configure an **API Gateway REST API as an MCP tool provider**
4.  Test the MCP tools using curl

Responsibilities are split between Terraform and scripts.

  Component      Responsibility
  -------------- -------------------------------------------------------
  Terraform      Creates infrastructure (AgentCore Gateway + IAM role)
  Shell script   Creates/updates AgentCore target
  MCP requests   Discover and invoke tools

------------------------------------------------------------------------

# Prerequisites

You need:

-   AWS CLI configured
-   Terraform \>= 1.5
-   An existing **REST API deployed in API Gateway**
-   The API must have a **stage** (required by AgentCore)

Example REST API endpoint used in this demo:

    https://<rest-api-id>.execute-api.eu-west-1.amazonaws.com/demo/pets

------------------------------------------------------------------------

# Deployment

## Deploy AgentCore Gateway

    terraform init
    terraform apply

Terraform creates:

-   AgentCore Gateway
-   IAM role
-   `.agentcore-target-config.json`

Example Terraform output:

    agentcore_gateway_id
    petstore-agentcore-gateway-xxxxxxx

    agentcore_gateway_url
    https://petstore-agentcore-gateway-xxxxxxx.gateway.bedrock-agentcore.eu-west-1.amazonaws.com/mcp

------------------------------------------------------------------------

# Create the AgentCore Target

The target converts API operations into MCP tools.

Run:

    ./agentcore-target.sh <gateway_suffix>

Example:

    ./agentcore-target.sh vsldu0essy

The script:

1.  Creates the gateway target
2.  Lists targets
3.  Tests MCP tools

------------------------------------------------------------------------

# Target Configuration

Terraform generates:

    .agentcore-target-config.json

Example:

``` json
{
  "mcp": {
    "apiGateway": {
      "restApiId": "wzvhpzmn4b",
      "stage": "demo",
      "apiGatewayToolConfiguration": {
        "toolFilters": [
          { "filterPath": "/pets", "methods": ["GET"] },
          { "filterPath": "/pets/{petId}", "methods": ["GET"] }
        ],
        "toolOverrides": [
          {
            "name": "listPets",
            "method": "GET",
            "path": "/pets",
            "description": "List pets"
          },
          {
            "name": "getPetById",
            "method": "GET",
            "path": "/pets/{petId}",
            "description": "Get pet by id"
          }
        ]
      }
    }
  }
}
```

------------------------------------------------------------------------

# Testing the MCP Gateway
``` bash
## List available tools

    curl https://<gateway-url>/mcp -H "Content-Type: application/json" -d '{
      "jsonrpc":"2.0",
      "id":1,
      "method":"tools/list"
    }'

Expected output:

    petstore-restapi-target___listPets
    petstore-restapi-target___getPetById

------------------------------------------------------------------------

## Invoke listPets

    curl https://<gateway-url>/mcp -H "Content-Type: application/json" -d '{
      "jsonrpc":"2.0",
      "id":2,
      "method":"tools/call",
      "params":{
        "name":"petstore-restapi-target___listPets",
        "arguments":{}
      }
    }'

------------------------------------------------------------------------
```
# Cleanup

Remove the AgentCore target:

    ./agentcore-target-destroy.sh <gateway_suffix>

Destroy Terraform resources:

    terraform destroy

------------------------------------------------------------------------

# Key Design Decisions

### Terraform manages infrastructure only

Terraform supports:

    aws_bedrockagentcore_gateway

but **does not yet support**:

    aws_bedrockagentcore_gateway_target

Therefore the gateway target is created using the AWS CLI.

------------------------------------------------------------------------

# Security Considerations

For production deployments consider:

  Concern          Recommendation
  ---------------- -----------------------------------
  Authentication   Use IAM or API keys
  API exposure     Limit endpoints using toolFilters
  IAM roles        Apply least privilege
  Rate limiting    Configure API Gateway throttling

------------------------------------------------------------------------

# Pattern Summary

    Existing REST API
            │
            ▼
    API Gateway
            │
            ▼
    AgentCore Gateway
            │
            ▼
    MCP Tools
            │
            ▼
    AI Agents

------------------------------------------------------------------------

# Future Enhancements

Possible improvements:

-   automatic OpenAPI to MCP conversion
-   multi-API tool discovery
-   integration with Bedrock Agents
-   CI/CD automation
