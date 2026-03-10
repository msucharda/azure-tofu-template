module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  location = var.location
  name     = var.name

  tags = merge(var.tags, {
    managed-by = "opentofu"
  })
}
