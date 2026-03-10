# Resource Group Module

Wrapper around the [Azure Verified Module for Resource Groups](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest).

## Purpose

Creates an Azure Resource Group with CAF naming conventions and mandatory tagging.

## AVM Source

| Module | Version |
|--------|---------|
| `Azure/avm-res-resources-resourcegroup/azurerm` | `~> 0.2` |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | Resource group name (must start with `rg-`) |
| `location` | `string` | Yes | Azure region |
| `tags` | `map(string)` | No | Additional tags (`managed-by` always added) |

## Outputs

| Name | Description |
|------|-------------|
| `name` | The resource group name |
| `resource_id` | The resource group ARM resource ID |

## Usage

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = "rg-contoso-dev"
  location = "westeurope"
  tags     = { environment = "dev" }
}
```
