# variables.tf — Root module variable declarations
#
# All input variables for the root module. Environment-specific values
# are provided via .tfvars files in the environments/ directory.
#
# Related files:
#   environments/dev.tfvars        — Dev variable values
#   environments/staging.tfvars    — Staging variable values
#   environments/production.tfvars — Production variable values

variable "subscription_id" {
  description = "The Azure subscription ID to deploy resources into."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid UUID."
  }
}

variable "location" {
  description = "The Azure region for resource deployment (e.g., westeurope, eastus)."
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "The deployment environment name. Must be one of: dev, staging, production."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "naming_prefix" {
  description = "Prefix used for resource naming following CAF conventions (e.g., 'contoso')."
  type        = string

  validation {
    condition     = length(var.naming_prefix) >= 2 && length(var.naming_prefix) <= 10
    error_message = "naming_prefix must be between 2 and 10 characters."
  }
}

variable "tags" {
  description = "Tags applied to all resources. The 'managed-by' tag is always included."
  type        = map(string)
  default     = {}
}

# --- Module toggle variables ---

variable "enable_networking" {
  description = "Whether to deploy the networking module (virtual network, subnets, NSG)."
  type        = bool
  default     = true
}

variable "enable_identity" {
  description = "Whether to deploy the identity module (user-assigned managed identity)."
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Whether to deploy the key vault module."
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Whether to deploy the storage account module."
  type        = bool
  default     = true
}
