# main.tf — Root module composition
#
# This file composes all child modules into a complete infrastructure stack.
# Each module is conditionally deployed via toggle variables (enable_*).
# The resource group is always created; other modules depend on it.
#
# Related files:
#   variables.tf   — Input variable declarations
#   outputs.tf     — Output value declarations
#   providers.tf   — Azure provider configuration
#   versions.tf    — Version constraints
#   backend.tf     — Remote state backend configuration

# Locals for CAF naming and mandatory tagging.
locals {
  # CAF resource type abbreviations
  caf_abbreviations = {
    resource_group         = "rg"
    virtual_network        = "vnet"
    user_assigned_identity = "id"
    key_vault              = "kv"
    storage_account        = "st"
  }

  # Mandatory tags applied to every resource
  base_tags = merge(var.tags, {
    managed-by  = "opentofu"
    environment = var.environment
  })

  # Resource names following CAF convention: <abbreviation>-<prefix>-<env>
  rg_name   = "${local.caf_abbreviations.resource_group}-${var.naming_prefix}-${var.environment}"
  vnet_name = "${local.caf_abbreviations.virtual_network}-${var.naming_prefix}-${var.environment}"
  id_name   = "${local.caf_abbreviations.user_assigned_identity}-${var.naming_prefix}-${var.environment}"
  kv_name   = "${local.caf_abbreviations.key_vault}-${var.naming_prefix}-${var.environment}"
  # Storage account names must be lowercase alphanumeric, 3-24 chars
  st_name = "${local.caf_abbreviations.storage_account}${var.naming_prefix}${var.environment}"
}

# --- Data sources ---

data "azurerm_client_config" "current" {}

# --- Resource Group (always deployed) ---

module "resource_group" {
  source = "./modules/resource-group"

  name     = local.rg_name
  location = var.location
  tags     = local.base_tags
}

# --- Networking (conditional) ---

module "networking" {
  source = "./modules/networking"
  count  = var.enable_networking ? 1 : 0

  name                = local.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.base_tags

  depends_on = [module.resource_group]
}

# --- Identity (conditional) ---

module "identity" {
  source = "./modules/identity"
  count  = var.enable_identity ? 1 : 0

  name                = local.id_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.base_tags

  depends_on = [module.resource_group]
}

# --- Key Vault (conditional) ---

module "key_vault" {
  source = "./modules/key-vault"
  count  = var.enable_key_vault ? 1 : 0

  name                = local.kv_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.base_tags

  depends_on = [module.resource_group]
}

# --- Storage Account (conditional) ---

module "storage" {
  source = "./modules/storage"
  count  = var.enable_storage ? 1 : 0

  name                = local.st_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.base_tags

  depends_on = [module.resource_group]
}
