output "name" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "resource_id" {
  description = "The resource ID of the storage account."
  value       = module.storage_account.resource_id
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint of the storage account."
  value       = module.storage_account.primary_blob_endpoint
}
