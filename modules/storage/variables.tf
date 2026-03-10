variable "name" {
  description = "The name of the storage account following CAF conventions. Must be 3-24 chars, lowercase alphanumeric."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "The Azure region for the storage account."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the storage account into."
  type        = string
}

variable "account_tier" {
  description = "The performance tier of the storage account."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "The replication type for the storage account."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "tags" {
  description = "Additional tags to apply. The 'managed-by' tag is always added."
  type        = map(string)
  default     = {}
}
