#!/usr/bin/env bash
set -euo pipefail

usage() {
cat <<EOF
Usage:
  ./agentcore-target-destroy.sh <gateway_suffix> [region] [target_name]

Example:
  ./agentcore-target-destroy.sh vsldu0essy
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
TARGET_NAME="${3:-petstore-restapi-target}"

require_cmd aws

GATEWAY_ID="petstore-agentcore-gateway-${GATEWAY_SUFFIX}"

echo "Gateway: $GATEWAY_ID"
echo "Region : $REGION"
echo "Target : $TARGET_NAME"
echo

echo "Finding target..."

TARGET_ID=$(aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" \
  --query "items[?name=='${TARGET_NAME}'].targetId | [0]" \
  --output text)

if [ -z "$TARGET_ID" ] || [ "$TARGET_ID" = "None" ] || [ "$TARGET_ID" = "null" ]; then
  echo "No target found with name: $TARGET_NAME"
  exit 0
fi

echo "Target found: $TARGET_ID"
echo "Deleting target..."

aws bedrock-agentcore-control delete-gateway-target \
  --gateway-identifier "$GATEWAY_ID" \
  --target-id "$TARGET_ID" \
  --region "$REGION"

echo
echo "Verifying deletion..."

aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" \
  --output table

echo
echo "Target successfully removed."