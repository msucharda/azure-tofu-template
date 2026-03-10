#!/usr/bin/env bash
#
# drift-detect.sh — Detect configuration drift in an environment.
#
# Usage:
#   ./scripts/drift-detect.sh <environment>
#
# Arguments:
#   environment  One of: dev, staging, production
#
# Exit codes:
#   0  No drift detected
#   1  Error
#   2  Drift detected (resources to add/change/destroy)

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

echo "=== Drift Detection for environment: $ENV ==="
echo ""

# --- Initialize ---

cd "$PROJECT_ROOT"
tofu init -backend-config="$BACKEND_CONFIG" -input=false -reconfigure > /dev/null 2>&1

# --- Run plan and capture output ---

PLAN_OUTPUT=$(tofu plan \
  -var-file="environments/${ENV}.tfvars" \
  -detailed-exitcode \
  -no-color \
  -input=false 2>&1) || PLAN_EXIT=$?

PLAN_EXIT="${PLAN_EXIT:-0}"

# --- Parse and report results ---

echo "$PLAN_OUTPUT"
echo ""

case $PLAN_EXIT in
  0)
    echo "✅ No drift detected — state matches live infrastructure."
    exit 0
    ;;
  2)
    # Extract summary line
    SUMMARY=$(echo "$PLAN_OUTPUT" | grep -E "Plan:|No changes" | tail -1)
    echo "⚠️  Drift detected!"
    echo "  $SUMMARY"
    echo ""
    echo "Run 'tofu apply -var-file=environments/${ENV}.tfvars' to reconcile."
    exit 2
    ;;
  *)
    echo "❌ Error running plan (exit code: $PLAN_EXIT)"
    exit 1
    ;;
esac
