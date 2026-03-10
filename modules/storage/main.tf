module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  account_tier               = var.account_tier
  account_replication_type   = var.account_replication_type
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  blob_properties = {
    versioning_enabled = true
  }

  tags = merge(var.tags, {
    managed-by = "opentofu"
  })
}
