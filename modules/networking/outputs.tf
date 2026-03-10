output "name" {
  description = "The name of the virtual network."
  value       = module.virtual_network.name
}

output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = module.virtual_network.resource_id
}

output "subnets" {
  description = "Map of subnet names to their properties."
  value       = module.virtual_network.subnets
}
