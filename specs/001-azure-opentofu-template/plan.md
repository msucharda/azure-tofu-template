# Implementation Plan: Azure OpenTofu Template Repository

**Branch**: `001-azure-opentofu-template` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-azure-opentofu-template/spec.md`

## Summary

Build a GitHub template repository that provides a complete, ready-to-use
OpenTofu project structure for managing Azure infrastructure on a per-subscription
basis. The template ships with Azure Verified Modules for baseline resources,
GitHub Actions CI/CD pipelines (validate on PR, apply on merge, destroy with
confirmation), branch-per-environment layout with one state file per environment,
security guardrails (no secrets, least-privilege RBAC, mandatory scanning), state
recovery runbooks, and an AI-friendly structure optimized for Copilot CLI.

## Technical Context

**Language/Version**: HCL — OpenTofu >= 1.8
**Primary Dependencies**: Azure Verified Modules (AVM), azurerm provider >= 4.0,
azapi provider (fallback only)
**Storage**: Azure Storage Account with blob versioning (remote state backend)
**Testing**: `tofu validate`, `tflint` (azurerm ruleset), `checkov`, `trivy`
**Target Platform**: GitHub (template repository) → Azure (deployment target)
**Project Type**: IaC template repository
**Performance Goals**: N/A — infrastructure provisioning, not runtime
**Constraints**: Azure-only, HCL-only, AVM-first, branch-per-environment,
one state file per environment, no hardcoded secrets
**Scale/Scope**: Per-subscription template, 3 environments (dev, staging,
production), ~5 baseline AVM modules, 3 GitHub Actions workflows

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Evidence |
|---|-----------|--------|----------|
| I | Azure Verified Modules First | ✅ PASS | FR-003: baseline modules use AVM; raw resources only with justification per constitution |
| II | Security by Default | ✅ PASS | FR-010–013: no secrets, Key Vault integration, least-privilege RBAC, mandatory scan |
| III | Branch-Per-Environment with GitFlow | ✅ PASS | FR-001: env branches; spec US2: PR-driven workflow; no direct pushes |
| IV | One Statefile Per Environment | ✅ PASS | FR-014–016: single state per env, remote with encryption, locking, versioning |
| V | Full Lifecycle Coverage | ✅ PASS | FR-002 (create), FR-007 (update/apply), FR-009 (destroy), FR-017 (recovery) |
| VI | AI-Assisted Development | ✅ PASS | FR-018–020: consistent naming, explicit variables, comprehensive docs |
| — | Technology Stack & Standards | ✅ PASS | OpenTofu (not Terraform), Azure-only, HCL, module pinning, CAF naming, tagging |
| — | PR Workflow & Quality Gates | ✅ PASS | FR-005–008: fmt, validate, plan, tflint, checkov/trivy, approval gates |

**Gate result: PASS** — no violations, no entries needed in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-azure-opentofu-template/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
.github/
├── workflows/
│   ├── pr-validate.yml          # PR pipeline: fmt, validate, plan, lint, scan
│   ├── apply.yml                # Apply on merge to environment branch
│   └── destroy.yml              # Destroy with manual confirmation gate
├── agents/                      # Speckit agent definitions
└── prompts/                     # Speckit prompt files

modules/                         # Reusable AVM-wrapping modules
├── resource-group/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── identity/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── key-vault/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── storage/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

main.tf                          # Root module — composes modules
variables.tf                     # Root variable declarations
outputs.tf                       # Root output declarations
providers.tf                     # Provider configuration (azurerm, azapi)
versions.tf                      # Required providers + version constraints
backend.tf                       # Backend config (partial, completed by init)

environments/                    # Environment-specific parameterization
├── dev.tfvars                   # Variable values for dev
├── staging.tfvars               # Variable values for staging
└── production.tfvars            # Variable values for production

backend-config/                  # Backend partial configs per environment
├── dev.hcl                      # State backend for dev
├── staging.hcl                  # State backend for staging
└── production.hcl               # State backend for production

scripts/                         # Operational helper scripts
├── init-backend.sh              # Initialize state backend for an environment
├── state-import.sh              # Import existing Azure resources into state
├── state-recover.sh             # Restore state from blob version backup
└── drift-detect.sh              # Compare state against live Azure resources

docs/                            # Runbooks and documentation
├── onboarding.md                # New subscription setup guide
├── making-changes.md            # PR workflow walkthrough
├── identity-setup.md            # OIDC WIF and service principal setup
├── github-setup.md              # Branch protection and environment config
├── destroying-resources.md      # Safe teardown procedures
└── state-recovery.md            # State restore/import/drift runbook

.gitignore                       # Ignore .terraform/, *.tfstate, etc.
.tflint.hcl                      # tflint configuration (azurerm ruleset)
.trivyignore                     # Trivy false-positive suppressions
README.md                        # Project overview and quick-start
```

**Structure Decision**: Single-project IaC layout (not web app or mobile).
The root directory IS the OpenTofu root module. Modules are local
wrappers around Azure Verified Modules. Environment differentiation
is achieved through `.tfvars` and partial backend configs, selected
by the CI/CD pipeline based on the target branch name. No separate
`src/` or `tests/` directories — testing is handled by the pipeline
tools (`tofu validate`, `tflint`, `checkov`, `trivy`).

## Complexity Tracking

> No constitution violations — table intentionally left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
