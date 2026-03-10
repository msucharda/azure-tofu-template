# Azure OpenTofu Template — Copilot Instructions

These instructions help GitHub Copilot CLI understand this project's conventions.

## Project Overview

This is an Azure infrastructure-as-code template repository using OpenTofu (not Terraform).
Each new Azure subscription gets a clone of this template. It follows a branch-per-environment
GitFlow workflow with three environments: dev, staging, production.

## Technology Stack

- **IaC Runtime**: OpenTofu >= 1.8
- **Provider**: azurerm >= 4.0, azapi >= 2.0 (fallback only)
- **Modules**: Azure Verified Modules (AVM) — always prefer AVM over raw resources
- **CI/CD**: GitHub Actions with OIDC Workload Identity Federation
- **Security Scanning**: checkov + trivy
- **Linting**: tflint with azurerm ruleset

## Project Structure

```text
main.tf            — Root module composing all child modules
variables.tf       — Root variable declarations with validation
outputs.tf         — Root output declarations
providers.tf       — Azure provider configuration
versions.tf        — OpenTofu and provider version constraints
backend.tf         — Partial backend config (completed at init)

modules/           — Local wrappers around Azure Verified Modules
  resource-group/  — AVM resource group wrapper
  networking/      — AVM virtual network wrapper
  identity/        — AVM managed identity wrapper
  key-vault/       — AVM key vault wrapper
  storage/         — AVM storage account wrapper

environments/      — Per-environment variable values (.tfvars)
backend-config/    — Per-environment backend configs (.hcl)
scripts/           — Operational helper scripts
docs/              — Runbooks and guides
.github/workflows/ — CI/CD pipelines
```

## Key Conventions

### Module Pattern

Every module is a thin wrapper around an AVM module:

```hcl
module "<name>" {
  source  = "Azure/<avm-module>/azurerm"
  version = "~> X.Y"    # Always pin version

  # Pass through variables
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Always merge mandatory tags
  tags = merge(var.tags, {
    managed-by = "opentofu"
  })
}
```

### Variable Declarations

All variables MUST have:
- `description` — clear, one-line description
- `type` — explicit type constraint
- `validation` — where applicable (naming patterns, allowed values)

### Naming Convention (CAF)

Resources follow Azure Cloud Adoption Framework abbreviations:
- Resource groups: `rg-<prefix>-<env>`
- Virtual networks: `vnet-<prefix>-<env>`
- Managed identities: `id-<prefix>-<env>`
- Key vaults: `kv-<prefix>-<env>`
- Storage accounts: `st<prefix><env>` (no hyphens)

### Tagging

Every resource MUST have at minimum:
- `managed-by = "opentofu"`
- `environment = "<env>"`

### No Hardcoded Secrets

Never put credentials, tokens, or secrets in `.tf` or `.tfvars` files.
Use Azure Key Vault data sources:

```hcl
data "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  key_vault_id = module.key_vault[0].resource_id
}
```

## Common Operations

```bash
# Initialize for an environment
./scripts/init-backend.sh dev

# Plan changes
tofu plan -var-file=environments/dev.tfvars

# Format all files
tofu fmt -recursive

# Validate configuration
tofu validate

# Detect drift
./scripts/drift-detect.sh dev

# Recover state
./scripts/state-recover.sh dev

# Import existing resource
./scripts/state-import.sh dev <address> <azure_id>
```

## Adding a New Module

1. Create `modules/<name>/main.tf`, `variables.tf`, `outputs.tf`
2. Use an AVM module as the source with a pinned version
3. Add validation blocks to variables
4. Merge `managed-by` tag in the module
5. Add a `module` block in root `main.tf` with a toggle variable
6. Add the toggle variable to `variables.tf`
7. Add outputs to root `outputs.tf`
8. Add variable values to each `environments/*.tfvars`
9. Create `modules/<name>/README.md`
10. Run `tofu fmt -recursive && tofu validate`

## PR Workflow

All changes go through pull requests:
1. Branch from the target environment branch
2. Make changes and test locally with `tofu plan`
3. Push and open a PR
4. Review automated checks (fmt, validate, plan, lint, scan)
5. Get approval (1 for dev/staging, 2 for production)
6. Merge — apply runs automatically
