# Azure OpenTofu Template

A GitHub template repository for managing Azure infrastructure with OpenTofu. Initialize this template for every new Azure subscription to get a secure, consistent, and automated IaC workflow.

## What's Included

| Component | Description |
|-----------|-------------|
| **Baseline modules** | Azure Verified Module wrappers for resource groups, networking, identity, key vault, and storage |
| **CI/CD pipelines** | GitHub Actions for PR validation (fmt, validate, plan, lint, scan), apply on merge, and destroy with confirmation |
| **Environment layout** | Branch-per-environment (dev, staging, production) with isolated state files |
| **Security guardrails** | No hardcoded secrets, OIDC authentication, least-privilege RBAC, mandatory scanning |
| **Recovery tooling** | Scripts for state backup, restore, import, and drift detection |

## Quick Start

```bash
# 1. Create a repo from this template and clone it
git clone https://github.com/<org>/<repo-name>.git && cd <repo-name>

# 2. Configure your subscription parameters
vi environments/dev.tfvars      # Set subscription_id, location, naming_prefix
vi backend-config/dev.hcl       # Set storage account details for state

# 3. Initialize the state backend
./scripts/init-backend.sh dev

# 4. Verify with a plan
tofu plan -var-file=environments/dev.tfvars
```

See [docs/onboarding.md](docs/onboarding.md) for the full setup guide.

## Directory Structure

```text
.
├── main.tf                     # Root module — composes all modules
├── variables.tf                # Root variable declarations
├── outputs.tf                  # Root output declarations
├── providers.tf                # Azure provider configuration
├── versions.tf                 # OpenTofu and provider version constraints
├── backend.tf                  # Remote state backend (partial config)
│
├── modules/                    # Reusable AVM-wrapping modules
│   ├── resource-group/
│   ├── networking/
│   ├── identity/
│   ├── key-vault/
│   └── storage/
│
├── environments/               # Per-environment variable values
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── production.tfvars
│
├── backend-config/             # Per-environment backend configuration
│   ├── dev.hcl
│   ├── staging.hcl
│   └── production.hcl
│
├── .github/workflows/          # CI/CD pipelines
│   ├── pr-validate.yml
│   ├── apply.yml
│   └── destroy.yml
│
├── scripts/                    # Operational helper scripts
│   ├── init-backend.sh
│   ├── state-recover.sh
│   ├── state-import.sh
│   └── drift-detect.sh
│
└── docs/                       # Runbooks and guides
    ├── onboarding.md
    ├── making-changes.md
    ├── identity-setup.md
    ├── github-setup.md
    ├── destroying-resources.md
    └── state-recovery.md
```

## Common Operations

| Task | Command |
|------|---------|
| Run a local plan | `tofu plan -var-file=environments/<env>.tfvars` |
| Add a new resource | Create/modify module in `modules/`, reference in `main.tf` |
| Promote to staging | Open PR from `dev` → `staging`, review, merge |
| Destroy environment | Trigger `destroy.yml` via GitHub Actions UI |
| Recover state | `./scripts/state-recover.sh <env>` |
| Import resource | `./scripts/state-import.sh <env> <addr> <azure_id>` |
| Detect drift | `./scripts/drift-detect.sh <env>` |

## Documentation

- [Onboarding Guide](docs/onboarding.md) — New subscription setup
- [Making Changes](docs/making-changes.md) — PR workflow walkthrough
- [Identity Setup](docs/identity-setup.md) — OIDC and service principal configuration
- [GitHub Setup](docs/github-setup.md) — Branch protection and environments
- [Destroying Resources](docs/destroying-resources.md) — Safe teardown procedures
- [State Recovery](docs/state-recovery.md) — Backup, restore, import, drift

## Principles

This project follows a [constitution](.specify/memory/constitution.md) with six core principles:

1. **Azure Verified Modules First** — AVM for all resources; raw only with justification
2. **Security by Default** — No secrets in code, RBAC least-privilege, encrypted state
3. **Branch-Per-Environment** — GitFlow PR-driven workflow, no direct pushes
4. **One Statefile Per Environment** — Isolated state with locking and versioning
5. **Full Lifecycle Coverage** — Create, update, destroy, and recover
6. **AI-Assisted Development** — Optimized for Copilot CLI and speckit agents
