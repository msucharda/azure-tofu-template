variable "name" {
  description = "The name of the Key Vault following CAF conventions (e.g., kv-contoso-dev)."
  type        = string

  validation {
    condition     = can(regex("^kv-", var.name))
    error_message = "Key Vault name must start with 'kv-' per CAF naming conventions."
  }

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24
    error_message = "Key Vault name must be between 3 and 24 characters."
  }
}

variable "location" {
  description = "The Azure region for the Key Vault."
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the Key Vault into."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "tenant_id" {
  description = "The Azure AD tenant ID for the Key Vault."
  type        = string
}

variable "sku_name" {
  description = "The SKU of the Key Vault. Must be 'standard' or 'premium'."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days to retain soft-deleted keys, secrets, and certificates."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the Key Vault is accessible from the public internet."
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACL configuration for the Key Vault."
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Allow")
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
  })
  default = null
}

variable "tags" {
  description = "Additional tags to apply. The 'managed-by' tag is always added."
  type        = map(string)
  default     = {}
}
