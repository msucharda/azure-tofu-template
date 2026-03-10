variable "name" {
  description = "The name of the virtual network following CAF conventions (e.g., vnet-contoso-dev)."
  type        = string

  validation {
    condition     = can(regex("^vnet-", var.name))
    error_message = "Virtual network name must start with 'vnet-' per CAF naming conventions."
  }
}

variable "location" {
  description = "The Azure region for the virtual network."
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the virtual network into."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "address_space" {
  description = "The address space for the virtual network in CIDR notation."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = <<-EOT
    Map of subnet configurations. Each key is the subnet name, and the value
    contains the subnet properties including address prefix.
  EOT
  type = map(object({
    name             = optional(string)
    address_prefix   = optional(string)
    address_prefixes = optional(list(string))
  }))
  default = {
    default = {
      address_prefix = "10.0.1.0/24"
    }
  }
}

variable "tags" {
  description = "Additional tags to apply. The 'managed-by' tag is always added."
  type        = map(string)
  default     = {}
}
