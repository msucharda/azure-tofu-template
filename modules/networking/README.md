# Networking Module

Wrapper around the [Azure Verified Module for Virtual Networks](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest).

## Purpose

Creates an Azure Virtual Network with subnets, NSG association, and CAF naming.

## AVM Source

| Module | Version |
|--------|---------|
| `Azure/avm-res-network-virtualnetwork/azurerm` | `~> 0.7` |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | VNet name (must start with `vnet-`) |
| `location` | `string` | Yes | Azure region |
| `resource_group_name` | `string` | Yes | Target resource group |
| `address_space` | `list(string)` | No | CIDR blocks (default: `["10.0.0.0/16"]`) |
| `subnets` | `map(object)` | No | Subnet configurations |
| `tags` | `map(string)` | No | Additional tags (`managed-by` always added) |

## Outputs

| Name | Description |
|------|-------------|
| `name` | The virtual network name |
| `resource_id` | The virtual network ARM resource ID |
| `subnets` | Map of subnet names to their properties |

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  name                = "vnet-contoso-dev"
  location            = "westeurope"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]
  subnets = {
    default = { address_prefix = "10.0.1.0/24" }
    apps    = { address_prefix = "10.0.2.0/24" }
  }
}
```
