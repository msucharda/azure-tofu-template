# Research: Azure OpenTofu Template Repository

**Branch**: `001-azure-opentofu-template`
**Date**: 2026-03-10
**Status**: Complete — all decisions resolved, no open clarifications

## Technology Decisions

### 1. OpenTofu Version

**Decision**: OpenTofu >= 1.8
**Rationale**: OpenTofu 1.8+ provides stable provider-defined
function support, improved state encryption capabilities, and full
compatibility with the Azure Verified Modules ecosystem. The 1.8
series is the current stable line with active maintenance.
**Alternatives considered**:
- OpenTofu 1.6: Too old — missing provider-defined functions and
  state encryption improvements.
- OpenTofu 1.7: Viable but 1.8 is current stable with no breaking
  changes from 1.7.

### 2. Azure Provider Version

**Decision**: azurerm >= 4.0
**Rationale**: The azurerm 4.x provider is the current major version
with the latest Azure resource support. Azure Verified Modules target
4.x as their primary compatibility baseline. The 4.x line introduced
provider-defined functions and improved resource lifecycle handling.
**Alternatives considered**:
- azurerm 3.x: End-of-active-support; AVM modules are migrating to
  4.x-only.

### 3. Azure Verified Modules for Baseline Resources

**Decision**: Use AVM modules for all five baseline resource categories:
resource groups, networking (virtual network + subnets), identity
(user-assigned managed identity), key vault, and storage account.
**Rationale**: Constitution Principle I mandates AVM-first. AVM modules
provide secure defaults, consistent interfaces, and are maintained by
Microsoft. Wrapping them in local modules allows adding project-specific
defaults (tagging, naming) without modifying AVM source.
**Alternatives considered**:
- Raw `azurerm` resource blocks: Violates constitution Principle I.
  Only permitted with justification when no AVM module exists.
- Third-party modules (e.g., claranet, terraform-azurerm-*):
  Not Microsoft-maintained; inconsistent quality; violates AVM-first.

### 4. State Backend Configuration

**Decision**: Azure Storage Account with blob backend, one container
per environment, blob versioning enabled, RBAC-based access (no SAS
tokens), state locking via blob lease.
**Rationale**: Constitution Principle IV requires one state file per
environment with locking and recovery capability. Blob versioning
enables point-in-time recovery (FR-016). RBAC access satisfies
Principle II (Security by Default — never SAS tokens).
**Alternatives considered**:
- Azure Storage with SAS tokens: Violates constitution — SAS tokens
  are explicitly prohibited.
- Terraform Cloud / Spacelift backend: Adds external dependency;
  project targets self-contained Azure-only stack.
- One storage account per environment vs. one account with multiple
  containers: Single account with per-env containers is simpler to
  manage and provision; per-env accounts add unnecessary isolation
  overhead given RBAC scoping.

### 5. CI/CD Pipeline Approach

**Decision**: GitHub Actions with three workflow files — `pr-validate.yml`
(triggered on PR), `apply.yml` (triggered on merge to env branch),
`destroy.yml` (manual dispatch with confirmation).
**Rationale**: GitHub Actions is the native CI/CD for GitHub template
repositories. Three separate workflows provide clear separation of
concerns. Apply on merge (not on PR) prevents accidental provisioning
during review. Manual dispatch for destroy adds a confirmation gate.
**Alternatives considered**:
- Single monolithic workflow with conditional jobs: Harder to maintain,
  unclear audit trail, permission model is coarser.
- Azure DevOps Pipelines: Not GitHub-native; adds external tooling
  dependency for a GitHub template repository.

### 6. Security Scanning Tooling

**Decision**: checkov as primary IaC security scanner, trivy as
secondary/complementary scanner for broader vulnerability coverage.
Both run in the PR validation pipeline.
**Rationale**: checkov has the most comprehensive policy library for
OpenTofu/Terraform HCL with Azure-specific rules. trivy adds
container/dependency scanning if the template evolves. Both are
open-source, run without external service dependencies, and produce
SARIF output for GitHub Security integration.
**Alternatives considered**:
- tfsec: Merged into trivy; no longer maintained independently.
- Snyk IaC: Requires paid license for full features; external
  dependency.
- checkov alone: Viable, but trivy adds minimal overhead and covers
  edge cases checkov misses (e.g., supply chain checks on module
  sources).

### 7. Linting Configuration

**Decision**: tflint with the `tflint-ruleset-azurerm` plugin.
**Rationale**: tflint catches issues that `tofu validate` misses —
deprecated resource attributes, naming convention violations, and
Azure-specific best practices. The azurerm ruleset is maintained
alongside the provider.
**Alternatives considered**:
- tofu validate alone: Only checks syntax and basic type constraints;
  misses provider-specific issues.
- custom OPA/Rego policies: Over-engineered for a template baseline;
  can be added later as needed.

### 8. Environment Selection Strategy

**Decision**: CI/CD workflow determines the target environment from the
branch name. The workflow maps branch `dev` → `environments/dev.tfvars`
+ `backend-config/dev.hcl`, and so on for staging and production.
Environment configs live in the repository on all branches.
**Rationale**: Having all environment configs in every branch ensures
module code stays consistent across environments (FR-004, SC-005).
Branch-specific divergence is limited to variable values, not
structure. The workflow acts as the selector, not the branch content.
**Alternatives considered**:
- Environment configs only on their respective branches: Creates
  divergence risk; harder to review cross-environment consistency.
- Terraform workspaces: OpenTofu workspaces use a single backend
  with workspace-prefixed state keys — less isolation than dedicated
  containers and harder to manage RBAC per environment.

### 9. Authentication Model for Pipelines

**Decision**: Workload Identity Federation (OIDC) from GitHub Actions
to Azure, using a separate service principal per environment with
federated credentials scoped to the environment branch.
**Rationale**: OIDC eliminates stored secrets in GitHub (no client
secret rotation needed). Per-environment service principals enable
least-privilege RBAC scoping (Principle II). Federated credentials
can be scoped to specific branches via the subject claim.
**Alternatives considered**:
- Client secret stored in GitHub Secrets: Requires rotation management,
  secret sprawl; less secure than OIDC.
- Single service principal for all environments: Violates
  least-privilege; compromise of one environment exposes all.
- Managed Identity: Only works for self-hosted runners in Azure, not
  GitHub-hosted runners.

### 10. State Recovery Approach

**Decision**: Three documented procedures — (1) restore from blob
version via `state-recover.sh`, (2) import existing resources via
`state-import.sh`, (3) detect drift via `drift-detect.sh`. All
scripts are wrappers around `tofu state` commands with safety checks.
**Rationale**: Constitution Principle V requires full lifecycle
coverage including recovery. Separate scripts for each scenario
make the procedures discoverable and repeatable. Blob versioning
provides the backup mechanism; scripts automate the restore.
**Alternatives considered**:
- Manual `az storage blob` + `tofu import` commands documented in a
  runbook only: Error-prone, easy to mistype; scripts reduce risk.
- Third-party state management tools (e.g., spacelift, env0):
  External dependency; over-engineered for the template scope.
