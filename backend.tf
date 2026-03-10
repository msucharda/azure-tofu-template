# backend.tf — Remote state backend configuration (partial)
#
# Uses Azure Storage with blob locking for state management.
# The actual storage account details are provided at init time via:
#   tofu init -backend-config=backend-config/<env>.hcl
#
# Related files:
#   backend-config/dev.hcl        — Dev backend values
#   backend-config/staging.hcl    — Staging backend values
#   backend-config/production.hcl — Production backend values
#   scripts/init-backend.sh       — Automated backend initialization

terraform {
  backend "azurerm" {
    # Partial configuration — completed at init time via:
    #   tofu init -backend-config=backend-config/<env>.hcl
    #
    # Required values provided by the backend config file:
    #   resource_group_name  — Resource group containing the storage account
    #   storage_account_name — Storage account for state files
    #   container_name       — Blob container (one per environment)
    #   key                  — Blob name for the state file

    use_oidc = true
  }
}
