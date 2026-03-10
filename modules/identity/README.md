# Identity Module

Wrapper around the [Azure Verified Module for User-Assigned Managed Identity](https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm/latest).

## Purpose

Creates an Azure User-Assigned Managed Identity for workload identity scenarios.

## AVM Source

| Module | Version |
|--------|---------|
| `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | `~> 0.3` |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | Identity name (must start with `id-`) |
| `location` | `string` | Yes | Azure region |
| `resource_group_name` | `string` | Yes | Target resource group |
| `tags` | `map(string)` | No | Additional tags (`managed-by` always added) |

## Outputs

| Name | Description |
|------|-------------|
| `principal_id` | The managed identity principal ID |
| `client_id` | The managed identity client ID |
| `resource_id` | The managed identity ARM resource ID |

## Usage

```hcl
module "identity" {
  source = "./modules/identity"

  name                = "id-contoso-dev"
  location            = "westeurope"
  resource_group_name = module.resource_group.name
}
```
