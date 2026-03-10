# providers.tf — Azure provider configuration
#
# Configures the azurerm provider with secure defaults.
# The subscription_id is passed as a variable (never hardcoded).
#
# Related files:
#   versions.tf — Provider version constraints
#   backend.tf  — Remote state backend (also uses azurerm)

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  skip_provider_registration = false
  subscription_id            = var.subscription_id
}
