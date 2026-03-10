#!/usr/bin/env bash
#
# state-import.sh — Import an existing Azure resource into OpenTofu state.
#
# Usage:
#   ./scripts/state-import.sh <environment> <resource_address> <azure_resource_id>
#
# Arguments:
#   environment       One of: dev, staging, production
#   resource_address  The OpenTofu resource address (e.g., module.resource_group.azurerm_resource_group.this)
#   azure_resource_id The full Azure resource ID
#
# This script:
#   1. Initializes OpenTofu with the environment backend
#   2. Runs tofu import
#   3. Verifies the import with tofu plan

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argument validation ---

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <environment> <resource_address> <azure_resource_id>"
  echo ""
  echo "  environment:       dev | staging | production"
  echo "  resource_address:  OpenTofu resource address (e.g., module.storage.azurerm_storage_account.this)"
  echo "  azure_resource_id: Full Azure resource ID (e.g., /subscriptions/.../resourceGroups/.../...)"
  exit 1
fi

ENV="$1"
RESOURCE_ADDR="$2"
AZURE_ID="$3"

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
  echo "Error: environment must be one of: dev, staging, production"
  exit 1
fi

BACKEND_CONFIG="$PROJECT_ROOT/backend-config/${ENV}.hcl"

if [[ ! -f "$BACKEND_CONFIG" ]]; then
  echo "Error: Backend config not found: $BACKEND_CONFIG"
  exit 1
fi

echo "=== Importing resource into state for environment: $ENV ==="
echo "  Resource Address: $RESOURCE_ADDR"
echo "  Azure Resource ID: $AZURE_ID"
echo ""

# --- Initialize ---

cd "$PROJECT_ROOT"
echo "Initializing OpenTofu..."
tofu init -backend-config="$BACKEND_CONFIG" -input=false -reconfigure

# --- Import ---

echo ""
echo "Importing resource..."
tofu import \
  -var-file="environments/${ENV}.tfvars" \
  "$RESOURCE_ADDR" \
  "$AZURE_ID"

# --- Verify ---

echo ""
echo "Verifying import with tofu plan..."
tofu plan -var-file="environments/${ENV}.tfvars"

echo ""
echo "=== Import complete ==="
echo "Review the plan output above. Ideally, there should be no changes"
echo "(or only expected configuration drift to reconcile)."
