# Key Vault Module

Wrapper around the [Azure Verified Module for Key Vault](https://registry.terraform.io/modules/Azure/avm-res-keyvault-vault/azurerm/latest).

## Purpose

Creates an Azure Key Vault with RBAC authorization, purge protection, and
secure defaults. Includes a secrets consumption pattern for referencing
secrets in other modules.

## AVM Source

| Module | Version |
|--------|---------|
| `Azure/avm-res-keyvault-vault/azurerm` | `~> 0.9` |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | Key Vault name (must start with `kv-`, 3–24 chars) |
| `location` | `string` | Yes | Azure region |
| `resource_group_name` | `string` | Yes | Target resource group |
| `tenant_id` | `string` | Yes | Azure AD tenant ID |
| `sku_name` | `string` | No | SKU: `standard` or `premium` (default: `standard`) |
| `soft_delete_retention_days` | `number` | No | Retention days (7–90, default: 90) |
| `public_network_access_enabled` | `bool` | No | Public access (default: true) |
| `network_acls` | `object` | No | Network ACL configuration |
| `tags` | `map(string)` | No | Additional tags (`managed-by` always added) |

## Outputs

| Name | Description |
|------|-------------|
| `name` | The Key Vault name |
| `resource_id` | The Key Vault ARM resource ID |
| `uri` | The Key Vault URI |

## Consuming Secrets

To read secrets from this Key Vault in other modules:

```hcl
data "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  key_vault_id = module.key_vault[0].resource_id
}
```

**Never** hardcode secret values in `.tf` or `.tfvars` files.

## Usage

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  name                = "kv-contoso-dev"
  location            = "westeurope"
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
}
```
