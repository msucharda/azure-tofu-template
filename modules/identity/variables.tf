variable "name" {
  description = "The name of the user-assigned managed identity following CAF conventions (e.g., id-contoso-dev)."
  type        = string

  validation {
    condition     = can(regex("^id-", var.name))
    error_message = "Managed identity name must start with 'id-' per CAF naming conventions."
  }
}

variable "location" {
  description = "The Azure region for the managed identity."
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the managed identity into."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply. The 'managed-by' tag is always added."
  type        = map(string)
  default     = {}
}
