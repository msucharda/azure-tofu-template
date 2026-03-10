module "user_assigned_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "~> 0.3"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    managed-by = "opentofu"
  })
}
