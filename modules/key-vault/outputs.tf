output "name" {
  description = "The name of the Key Vault."
  value       = module.key_vault.name
}

output "resource_id" {
  description = "The resource ID of the Key Vault."
  value       = module.key_vault.resource_id
}

output "uri" {
  description = "The URI of the Key Vault."
  value       = module.key_vault.uri
}
