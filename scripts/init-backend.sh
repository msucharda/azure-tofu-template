#!/usr/bin/env bash
#
# init-backend.sh — Initialize OpenTofu backend for a given environment.
#
# Usage:
#   ./scripts/init-backend.sh <environment>
#
# Arguments:
#   environment  One of: dev, staging, production
#
# This script:
#   1. Validates the environment argument
#   2. Optionally creates the Azure Storage Account and container if they don't exist
#   3. Enables blob versioning for state recovery
#   4. Runs tofu init with the environment-specific backend config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argument validation ---

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <environment>"
  echo "  environment: dev | staging | production"
  exit 1
fi

ENV="$1"

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
  echo "Error: environment must be one of: dev, staging, production"
  exit 1
fi

BACKEND_CONFIG="$PROJECT_ROOT/backend-config/${ENV}.hcl"

if [[ ! -f "$BACKEND_CONFIG" ]]; then
  echo "Error: Backend config not found: $BACKEND_CONFIG"
  exit 1
fi

# --- Parse backend config ---

RG_NAME=$(grep 'resource_group_name' "$BACKEND_CONFIG" | cut -d'"' -f2)
SA_NAME=$(grep 'storage_account_name' "$BACKEND_CONFIG" | cut -d'"' -f2)
CONTAINER=$(grep 'container_name' "$BACKEND_CONFIG" | cut -d'"' -f2)

echo "=== Initializing backend for environment: $ENV ==="
echo "  Resource Group:    $RG_NAME"
echo "  Storage Account:   $SA_NAME"
echo "  Container:         $CONTAINER"
echo ""

# --- Create storage infrastructure if it doesn't exist ---

echo "Checking if resource group '$RG_NAME' exists..."
if ! az group show --name "$RG_NAME" --output none 2>/dev/null; then
  echo "Creating resource group '$RG_NAME'..."
  LOCATION=$(grep 'location' "$PROJECT_ROOT/environments/${ENV}.tfvars" | head -1 | cut -d'"' -f2)
  az group create --name "$RG_NAME" --location "${LOCATION:-westeurope}" --output none
  echo "  Resource group created."
else
  echo "  Resource group exists."
fi

echo "Checking if storage account '$SA_NAME' exists..."
if ! az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" --output none 2>/dev/null; then
  echo "Creating storage account '$SA_NAME'..."
  az storage account create \
    --name "$SA_NAME" \
    --resource-group "$RG_NAME" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true \
    --output none
  echo "  Storage account created."
else
  echo "  Storage account exists."
fi

echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --enable-versioning true \
  --output none
echo "  Blob versioning enabled."

echo "Checking if container '$CONTAINER' exists..."
if ! az storage container show --name "$CONTAINER" --account-name "$SA_NAME" --auth-mode login --output none 2>/dev/null; then
  echo "Creating container '$CONTAINER'..."
  az storage container create \
    --name "$CONTAINER" \
    --account-name "$SA_NAME" \
    --auth-mode login \
    --output none
  echo "  Container created."
else
  echo "  Container exists."
fi

# --- Initialize OpenTofu ---

echo ""
echo "Running tofu init with backend config: $BACKEND_CONFIG"
cd "$PROJECT_ROOT"
tofu init -backend-config="$BACKEND_CONFIG" -reconfigure

echo ""
echo "=== Backend initialization complete for '$ENV' ==="
echo "Next steps:"
echo "  tofu plan -var-file=environments/${ENV}.tfvars"
