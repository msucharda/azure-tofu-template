# outputs.tf — Root module output declarations
#
# Exposes key attributes from deployed modules for use by other systems
# (scripts, CI/CD pipelines, or downstream configurations).
#
# Related files:
#   main.tf — Module composition that produces these outputs

# --- Resource Group outputs ---

output "resource_group_name" {
  description = "The name of the primary resource group."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "The resource ID of the primary resource group."
  value       = module.resource_group.resource_id
}

# --- Networking outputs ---

output "vnet_name" {
  description = "The name of the virtual network."
  value       = var.enable_networking ? module.networking[0].name : null
}

output "vnet_id" {
  description = "The resource ID of the virtual network."
  value       = var.enable_networking ? module.networking[0].resource_id : null
}

# --- Identity outputs ---

output "identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity."
  value       = var.enable_identity ? module.identity[0].principal_id : null
}

# --- Key Vault outputs ---

output "key_vault_uri" {
  description = "The URI of the deployed Key Vault."
  value       = var.enable_key_vault ? module.key_vault[0].uri : null
}

# --- Storage outputs ---

output "storage_account_name" {
  description = "The name of the deployed storage account."
  value       = var.enable_storage ? module.storage[0].name : null
}
