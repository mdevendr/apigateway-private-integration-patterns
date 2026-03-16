#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./agentcore-target.sh <gateway_suffix> [region] [target_config_file]

Examples:
  ./agentcore-target.sh vsldu0essy
  ./agentcore-target.sh vsldu0essy eu-west-2
  ./agentcore-target.sh vsldu0essy eu-west-2 .agentcore-target-config.json
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { usage; exit 0; }
[ $# -lt 1 ] && { usage; fail "Missing gateway suffix"; }

GATEWAY_SUFFIX="$1"
REGION="${2:-eu-west-2}"
TARGET_CONFIG_FILE="${3:-.agentcore-target-config.json}"

[[ "$GATEWAY_SUFFIX" =~ ^[a-zA-Z0-9-]+$ ]] || fail "Invalid gateway suffix: $GATEWAY_SUFFIX"
[ -f "$TARGET_CONFIG_FILE" ] || fail "Target config file not found: $TARGET_CONFIG_FILE"
[ -s "$TARGET_CONFIG_FILE" ] || fail "Target config file is empty: $TARGET_CONFIG_FILE"

require_cmd aws
require_cmd curl

if command -v jq >/dev/null 2>&1; then
  jq empty "$TARGET_CONFIG_FILE" >/dev/null 2>&1 || fail "Invalid JSON: $TARGET_CONFIG_FILE"
fi

GATEWAY_ID="petstore-agentcore-gateway-${GATEWAY_SUFFIX}"
GATEWAY_URL="https://${GATEWAY_ID}.gateway.bedrock-agentcore.${REGION}.amazonaws.com/mcp"
TARGET_NAME="petstore-restapi-target"

echo "Gateway ID: $GATEWAY_ID"
echo "Region: $REGION"
echo "Target config: $TARGET_CONFIG_FILE"
echo

EXISTING_TARGET_ID="$(aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" \
  --query "items[?name=='${TARGET_NAME}'].targetId | [0]" \
  --output text)"

if [ -n "$EXISTING_TARGET_ID" ] && [ "$EXISTING_TARGET_ID" != "None" ] && [ "$EXISTING_TARGET_ID" != "null" ]; then
  echo "Updating existing target: $EXISTING_TARGET_ID"
  aws bedrock-agentcore-control update-gateway-target \
    --gateway-identifier "$GATEWAY_ID" \
    --target-id "$EXISTING_TARGET_ID" \
    --name "$TARGET_NAME" \
    --description "PetStore REST API target" \
    --target-configuration "file://${TARGET_CONFIG_FILE}" \
    --region "$REGION"
else
  echo "Creating new target"
  aws bedrock-agentcore-control create-gateway-target \
    --gateway-identifier "$GATEWAY_ID" \
    --name "$TARGET_NAME" \
    --description "PetStore REST API target" \
    --target-configuration "file://${TARGET_CONFIG_FILE}" \
    --region "$REGION"
fi

echo
echo "Listing targets..."
aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" \
  --output table

echo
echo "Testing tools/list..."
curl -sS "$GATEWAY_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/list"
  }'
echo

echo "Testing tools/call listPets..."
curl -sS "$GATEWAY_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{
      "name":"petstore-restapi-target___listPets",
      "arguments":{}
    }
  }'

echo "Testing tools/call getPetById..."
curl -sS "$GATEWAY_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"petstore-restapi-target___getPetById",
      "arguments":{
        "petId": 1
      }
    }
  }']
echo