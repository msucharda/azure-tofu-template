<!--
  Sync Impact Report
  ==================
  Version change: N/A (template) → 1.0.0
  Modified principles: None (initial creation)
  Added principles:
    - I. Azure Verified Modules First
    - II. Security by Default (NON-NEGOTIABLE)
    - III. Branch-Per-Environment with GitFlow
    - IV. One Statefile Per Environment
    - V. Full Lifecycle Coverage
    - VI. AI-Assisted Development with Copilot CLI
  Added sections:
    - Technology Stack & Standards
    - PR Workflow & Quality Gates
  Removed sections: None
  Templates requiring updates:
    ✅ .specify/templates/plan-template.md — no conflicts
    ✅ .specify/templates/spec-template.md — no conflicts
    ✅ .specify/templates/tasks-template.md — no conflicts
    ✅ .specify/templates/checklist-template.md — no conflicts
  Follow-up TODOs: None
-->

# Azure OpenTofu Template Constitution

## Core Principles

### I. Azure Verified Modules First

All Azure resources MUST be provisioned using Azure Verified Modules
(AVM). Raw `azurerm`/`azapi` resource blocks are only permitted when
no AVM module exists for the required resource. Any raw resource usage
MUST include a comment justifying why AVM was not used and a link to
the AVM tracking issue. This ensures consistency, security defaults,
and maintainability across all subscriptions.

### II. Security by Default (NON-NEGOTIABLE)

No hardcoded credentials, secrets, or tokens anywhere in the codebase.
All secrets MUST be managed through Azure Key Vault or
environment-scoped variables. Least-privilege RBAC assignments are
mandatory — no Owner or broad Contributor roles unless explicitly
justified and documented. Service principals and managed identities
MUST be scoped to the minimum required permissions. State files MUST
be stored in encrypted Azure Storage with access restricted via RBAC,
never SAS tokens.

### III. Branch-Per-Environment with GitFlow

Each environment (dev, staging, production) has a dedicated long-lived
branch. All changes follow a GitFlow PR-driven workflow: feature
branches are created from the target environment branch, changes are
submitted via pull request, reviewed, approved, and merged. Direct
pushes to environment branches are prohibited. PRs MUST pass
validation (`tofu plan`, linting, security scan) before merge.
Hotfixes follow the same PR process with expedited review.

### IV. One Statefile Per Environment

Each environment MUST have exactly one OpenTofu state file, stored in
a dedicated Azure Storage Account container per environment. State
locking MUST be enabled via Azure Blob lease. State files are never
shared across environments. Backend configuration is parameterized per
environment branch. State recovery procedures MUST exist and be
documented — including import workflows, `state mv` operations, and
backup/restore from versioned blob storage.

### V. Full Lifecycle Coverage

The project MUST support all stages of the OpenTofu infrastructure
lifecycle: creation (initial provisioning of a new subscription's
resources), updates (incremental changes via plan/apply), destruction
(controlled teardown with dependency-aware ordering and confirmation
gates), and state recovery (documented runbooks for re-importing
resources, resolving state drift, and restoring from blob snapshots).
Each lifecycle stage MUST have corresponding GitHub Actions workflows
or documented manual procedures.

### VI. AI-Assisted Development with Copilot CLI

Developers interact with this project primarily through GitHub Copilot
CLI and speckit AI agents. All specifications, plans, tasks, and
implementations are driven through the speckit workflow (specify → plan
→ tasks → implement). AI agents MUST follow the constitution
principles. Copilot CLI is the recommended interface for `tofu plan`,
`tofu apply`, code generation, and troubleshooting. Human review of
AI-generated changes remains mandatory via the PR workflow.

## Technology Stack & Standards

- OpenTofu (not HashiCorp Terraform) is the IaC runtime
- Azure is the sole cloud provider target
- HCL is the configuration language; no JSON configurations
- Module pinning is mandatory — all module sources MUST use version
  constraints
- All resources MUST be tagged with at minimum: `managed-by`
  (`opentofu`)
- Naming conventions follow Azure Cloud Adoption Framework (CAF)
  guidance

## PR Workflow & Quality Gates

- All changes require a pull request — no exceptions
- PRs MUST include: `tofu fmt` check, `tofu validate`, `tofu plan`
  output, `tflint` scan, and `checkov`/`trivy` security scan
- Minimum one approval required for dev/staging, two approvals for
  production
- Plan output MUST be posted as a PR comment for review
- Apply runs only after merge to the target environment branch
- Destroy operations require explicit manual approval in the GitHub
  Actions workflow

## Governance

- This constitution supersedes all ad-hoc practices and tribal
  knowledge
- Amendments require a PR with documented rationale and at least two
  approvals
- All PRs and code reviews MUST verify compliance with these
  principles
- Complexity deviations MUST be justified in the plan's Complexity
  Tracking table

**Version**: 1.0.0 | **Ratified**: 2026-03-10 | **Last Amended**: 2026-03-10
