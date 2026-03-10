# Quickstart: Azure OpenTofu Template Repository

**Branch**: `001-azure-opentofu-template`
**Date**: 2026-03-10
**Prerequisites**: Azure subscription, GitHub account, OpenTofu CLI
installed, Azure CLI (`az`) installed and authenticated

## 1. Create Repository from Template

Create a new GitHub repository using this template. Name it following
your organization's convention (e.g., `infra-<subscription-name>`).
Clone the new repository locally.

## 2. Configure Subscription Parameters

Edit the environment variable files to set your subscription-specific
values:

- `environments/dev.tfvars` — subscription ID, region, naming prefix,
  resource sizing for dev
- `environments/staging.tfvars` — same for staging
- `environments/production.tfvars` — same for production

Edit the backend configuration files:

- `backend-config/dev.hcl` — storage account name, container name,
  resource group for dev state
- `backend-config/staging.hcl` — same for staging
- `backend-config/production.hcl` — same for production

## 3. Initialize State Backend

Run the initialization script for each environment, starting with dev:

```
./scripts/init-backend.sh dev
```

This provisions the Azure Storage Account (if it doesn't exist), creates
the blob container for state, enables versioning, configures RBAC access,
and runs `tofu init` with the backend config.

## 4. Verify the Setup

After initialization, run a plan against dev to confirm everything works:

```
tofu plan -var-file=environments/dev.tfvars
```

The plan should complete with no errors. It will show the baseline
resources to be created (resource group, networking, identity, key vault,
storage).

## 5. Set Up GitHub Actions

Configure the following GitHub repository secrets/variables for each
environment:

- `AZURE_CLIENT_ID` — service principal client ID (per environment)
- `AZURE_TENANT_ID` — Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` — target subscription ID (per environment)

These are used by the OIDC Workload Identity Federation — no client
secrets needed.

Create GitHub environments (`dev`, `staging`, `production`) and configure:
- Required reviewers for production
- Branch protection rules on environment branches (require PR, require
  status checks, no direct pushes)

## 6. Create Environment Branches

Create the long-lived environment branches:

```
git checkout -b dev && git push -u origin dev
git checkout -b staging && git push -u origin staging
git checkout -b production && git push -u origin production
```

## 7. Make Your First Change

Create a feature branch from `dev`, make a change (e.g., adjust a
variable value), push, and open a PR targeting the `dev` branch.

The `pr-validate` workflow will run automatically — check the PR
comment for the plan output and scan results.

After approval, merge the PR. The `apply` workflow triggers and
provisions the change in the dev environment.

## 8. Common Operations

| Task | Command / Action |
|------|-----------------|
| Run a local plan | `tofu plan -var-file=environments/<env>.tfvars` |
| Add a new resource | Create/modify module in `modules/`, reference in `main.tf`, set vars in `environments/*.tfvars` |
| Promote to staging | Open PR from `dev` → `staging`, review, merge |
| Destroy environment | Trigger `destroy.yml` workflow manually via GitHub Actions UI |
| Recover state | See `docs/state-recovery.md` or run `./scripts/state-recover.sh <env>` |
| Import existing resource | Run `./scripts/state-import.sh <env> <resource_addr> <azure_id>` |
| Detect drift | Run `./scripts/drift-detect.sh <env>` |

## 9. Next Steps

- Review `docs/onboarding.md` for detailed setup instructions
- Review `docs/making-changes.md` for the full PR workflow guide
- Review `docs/state-recovery.md` for recovery runbooks
- Customize the baseline modules in `modules/` for your
  subscription's specific needs
