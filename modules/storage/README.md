# Storage Account Module

Wrapper around the [Azure Verified Module for Storage Account](https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest).

## Purpose

Creates an Azure Storage Account with encryption, HTTPS-only, TLS 1.2,
and blob versioning enabled by default.

## AVM Source

| Module | Version |
|--------|---------|
| `Azure/avm-res-storage-storageaccount/azurerm` | `~> 0.4` |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | Storage account name (3–24 lowercase alphanumeric) |
| `location` | `string` | Yes | Azure region |
| `resource_group_name` | `string` | Yes | Target resource group |
| `account_tier` | `string` | No | `Standard` or `Premium` (default: `Standard`) |
| `account_replication_type` | `string` | No | Replication: LRS, GRS, etc. (default: `LRS`) |
| `tags` | `map(string)` | No | Additional tags (`managed-by` always added) |

## Outputs

| Name | Description |
|------|-------------|
| `name` | The storage account name |
| `resource_id` | The storage account ARM resource ID |
| `primary_blob_endpoint` | The primary blob endpoint URL |

## Usage

```hcl
module "storage" {
  source = "./modules/storage"

  name                = "stcontosodev"
  location            = "westeurope"
  resource_group_name = module.resource_group.name
}
```
