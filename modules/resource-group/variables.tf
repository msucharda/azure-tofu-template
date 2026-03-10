variable "name" {
  description = "The name of the resource group following CAF conventions (e.g., rg-contoso-dev)."
  type        = string

  validation {
    condition     = can(regex("^rg-", var.name))
    error_message = "Resource group name must start with 'rg-' per CAF naming conventions."
  }

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 90
    error_message = "Resource group name must be between 3 and 90 characters."
  }
}

variable "location" {
  description = "The Azure region for the resource group."
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "location must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply. The 'managed-by' tag is always added."
  type        = map(string)
  default     = {}
}
