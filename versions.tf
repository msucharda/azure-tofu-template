# versions.tf — OpenTofu and provider version constraints
#
# Pins the minimum OpenTofu version and provider versions to ensure
# reproducible builds across all environments and CI/CD runs.
#
# Related files:
#   providers.tf — Provider configuration
#   .terraform.lock.hcl — Provider dependency lock (committed)

terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }

    # azapi is included for future raw-resource fallback per Constitution
    # Principle I. Not used by baseline modules — only permitted when no
    # AVM module exists, with a justification comment and tracking issue link.
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0"
    }
  }
}
