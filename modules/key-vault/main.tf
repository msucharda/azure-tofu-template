module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name                      = var.sku_name
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  network_acls = var.network_acls

  tags = merge(var.tags, {
    managed-by = "opentofu"
  })

  # Secrets consumption pattern:
  # To read secrets from this Key Vault in other modules, use a data source:
  #
  #   data "azurerm_key_vault_secret" "example" {
  #     name         = "my-secret"
  #     key_vault_id = module.key_vault[0].resource_id
  #   }
  #
  # Never hardcode secret values in .tf or .tfvars files.
  # Store secrets in Key Vault via Azure CLI or Portal, then reference
  # them with data sources in your OpenTofu configuration.
}
