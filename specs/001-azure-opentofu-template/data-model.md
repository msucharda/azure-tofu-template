# Data Model: Azure OpenTofu Template Repository

**Branch**: `001-azure-opentofu-template`
**Date**: 2026-03-10
**Source**: [spec.md](spec.md) Key Entities + [research.md](research.md)

## Entities

### Environment

Represents a deployment target with its own isolated configuration,
state, and approval rules.

**Attributes**:
- `name`: Identifier — one of `dev`, `staging`, `production`
- `branch`: Corresponding long-lived Git branch (same as `name`)
- `tfvars_file`: Path to variable values (`environments/<name>.tfvars`)
- `backend_config`: Path to backend partial config (`backend-config/<name>.hcl`)
- `state_container`: Azure Storage blob container name (`tfstate-<name>`)
- `service_principal`: OIDC-federated identity for this environment
- `approval_count`: Required PR approvals (1 for dev/staging, 2 for production)
- `manual_apply_gate`: Whether apply requires manual approval (true for production)

**Relationships**:
- Has exactly one State File
- Has exactly one Deployment Identity (service principal)
- Has one or more Pipelines that target it
- Consumes the same set of Modules as all other environments

**Validation Rules**:
- Environment name MUST be one of the three defined values
- Backend config MUST point to a unique storage container
- State container names MUST NOT overlap across environments

---

### Module

A local wrapper around an Azure Verified Module that adds
project-specific defaults (naming, tagging, common variables).

**Attributes**:
- `name`: Module identifier (e.g., `resource-group`, `networking`)
- `source`: AVM module registry reference with version pin
- `variables`: Input variable definitions with types and descriptions
- `outputs`: Output value definitions
- `responsibility`: Single-purpose description of what the module provisions

**Relationships**:
- References exactly one Azure Verified Module (source)
- Consumed by the root module (`main.tf`) via `module` blocks
- May depend on outputs from other modules (e.g., networking depends
  on resource-group)

**Validation Rules**:
- MUST reference an AVM module source (or include justification comment)
- MUST pin the module version (no floating references)
- MUST define all input variables with `description` and `type`
- MUST include at least a `managed-by` tag on all resources

---

### State File

The OpenTofu state record for a single environment.

**Attributes**:
- `environment`: The environment this state belongs to
- `backend_type`: `azurerm` (Azure Storage blob)
- `storage_account`: Azure Storage Account name
- `container`: Blob container name (`tfstate-<env>`)
- `key`: Blob name (e.g., `terraform.tfstate`)
- `locking`: Enabled via blob lease
- `versioning`: Azure Blob versioning enabled for point-in-time recovery
- `encryption`: Encrypted at rest via Azure Storage encryption (SSE)

**Relationships**:
- Belongs to exactly one Environment
- Stored in one blob within one container in the Storage Account
- Locked during plan/apply/destroy operations

**State Transitions**:
- `uninitialized` → `initialized` (via `tofu init`)
- `initialized` → `active` (after first successful apply)
- `active` → `corrupted` (external modification, incomplete apply)
- `corrupted` → `recovered` (via restore from backup or re-import)
- `active` → `empty` (after full destroy)
- `active` → `deleted` (accidental deletion)
- `deleted` → `recovered` (via blob version restore)

---

### Pipeline

An automated GitHub Actions workflow triggered by repository events.

**Attributes**:
- `name`: Workflow identifier (`pr-validate`, `apply`, `destroy`)
- `trigger`: Event that starts the pipeline (PR open/sync, branch
  merge, manual dispatch)
- `target_environment`: Derived from the target branch name
- `steps`: Ordered list of operations the pipeline performs
- `gates`: Approval/confirmation requirements before execution

**Relationships**:
- Targets exactly one Environment per run
- Uses one Deployment Identity to authenticate with Azure
- Reads/writes one State File during plan/apply/destroy

**Pipeline Types**:

| Pipeline | Trigger | Steps | Gate |
|----------|---------|-------|------|
| pr-validate | PR opened/synchronized | fmt → validate → plan → lint → scan → comment | None (informational) |
| apply | Merge to env branch | init → plan → apply | Manual approval (production only) |
| destroy | Manual workflow dispatch | init → plan -destroy → confirm → destroy | Manual confirmation (all environments) |

---

### Deployment Identity

The service principal used by pipelines to authenticate with Azure
via OIDC Workload Identity Federation.

**Attributes**:
- `environment`: The environment this identity serves
- `client_id`: Azure AD application (client) ID
- `tenant_id`: Azure AD tenant ID
- `subscription_id`: Target Azure subscription
- `federated_credential_subject`: OIDC subject claim scoped to the
  environment branch (e.g., `repo:<org>/<repo>:ref:refs/heads/dev`)
- `role_assignments`: List of RBAC roles assigned at specific scopes

**Relationships**:
- Belongs to exactly one Environment
- Used by Pipelines targeting that environment
- Scoped to the target subscription with least-privilege roles

**Validation Rules**:
- MUST NOT have Owner or broad Contributor role unless justified
- Federated credential MUST be scoped to the specific environment
  branch — not wildcarded
- RBAC assignments MUST follow least-privilege: only the permissions
  needed for the resources managed by the template
