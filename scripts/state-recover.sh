#!/usr/bin/env bash
#
# state-recover.sh — Restore OpenTofu state from Azure Blob version backup.
#
# Usage:
#   ./scripts/state-recover.sh <environment>
#
# Arguments:
#   environment  One of: dev, staging, production
#
# This script:
#   1. Lists available blob versions for the state file
#   2. Prompts for version selection
#   3. Restores the selected version as the current state
#   4. Runs tofu plan to verify recovery

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

SA_NAME=$(grep 'storage_account_name' "$BACKEND_CONFIG" | cut -d'"' -f2)
CONTAINER=$(grep 'container_name' "$BACKEND_CONFIG" | cut -d'"' -f2)
KEY=$(grep '^key' "$BACKEND_CONFIG" | cut -d'"' -f2)

echo "=== State Recovery for environment: $ENV ==="
echo "  Storage Account: $SA_NAME"
echo "  Container:       $CONTAINER"
echo "  State Key:       $KEY"
echo ""

# --- List available versions ---

echo "Fetching available blob versions..."
VERSIONS=$(az storage blob list \
  --account-name "$SA_NAME" \
  --container-name "$CONTAINER" \
  --include v \
  --prefix "$KEY" \
  --auth-mode login \
  --query "[?name=='${KEY}'].{version:versionId, modified:properties.lastModified, size:properties.contentLength}" \
  --output table)

echo "$VERSIONS"
echo ""

# --- Prompt for version selection ---

echo "Available version IDs:"
VERSION_IDS=$(az storage blob list \
  --account-name "$SA_NAME" \
  --container-name "$CONTAINER" \
  --include v \
  --prefix "$KEY" \
  --auth-mode login \
  --query "[?name=='${KEY}'].versionId" \
  --output tsv)

INDEX=0
declare -a VERSION_ARRAY
while IFS= read -r vid; do
  VERSION_ARRAY+=("$vid")
  echo "  [$INDEX] $vid"
  INDEX=$((INDEX + 1))
done <<< "$VERSION_IDS"

echo ""
read -r -p "Enter version index to restore (or 'q' to quit): " CHOICE

if [[ "$CHOICE" == "q" ]]; then
  echo "Aborted."
  exit 0
fi

if [[ "$CHOICE" -lt 0 || "$CHOICE" -ge "${#VERSION_ARRAY[@]}" ]]; then
  echo "Error: invalid selection."
  exit 1
fi

SELECTED_VERSION="${VERSION_ARRAY[$CHOICE]}"
echo ""
echo "Restoring version: $SELECTED_VERSION"

# --- Download versioned blob and upload as current ---

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

echo "Downloading versioned state..."
az storage blob download \
  --account-name "$SA_NAME" \
  --container-name "$CONTAINER" \
  --name "$KEY" \
  --version-id "$SELECTED_VERSION" \
  --file "$TEMP_FILE" \
  --auth-mode login \
  --output none

echo "Uploading as current state..."
az storage blob upload \
  --account-name "$SA_NAME" \
  --container-name "$CONTAINER" \
  --name "$KEY" \
  --file "$TEMP_FILE" \
  --auth-mode login \
  --overwrite \
  --output none

echo "State restored successfully."
echo ""

# --- Verify recovery ---

echo "Verifying recovery with tofu plan..."
cd "$PROJECT_ROOT"
tofu init -backend-config="$BACKEND_CONFIG" -reconfigure
tofu plan -var-file="environments/${ENV}.tfvars"

echo ""
echo "=== State recovery complete for '$ENV' ==="
echo "Review the plan output above to verify the recovered state matches expectations."
