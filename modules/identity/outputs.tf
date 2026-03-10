output "principal_id" {
  description = "The principal ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.principal_id
}

output "client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.client_id
}

output "resource_id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = module.user_assigned_identity.resource_id
}
