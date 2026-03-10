# Onboarding: New Subscription Setup

This guide walks through setting up this template for a new Azure subscription.

## Prerequisites

- **Azure CLI** (`az`) installed and authenticated
- **OpenTofu** (`tofu`) >= 1.8 installed
- **GitHub CLI** (`gh`) installed (optional, for creating the repository)
- Azure subscription with Owner or Contributor access
- GitHub account with permission to create repositories from templates

## Step 1: Create Repository from Template

1. Navigate to the template repository on GitHub
2. Click **"Use this template"** → **"Create a new repository"**
3. Name it following your convention (e.g., `infra-<subscription-name>`)
4. Clone the new repository:

```bash
git clone https://github.com/<org>/<repo-name>.git
cd <repo-name>
```

## Step 2: Configure Subscription Parameters

### Environment Variables

Edit each environment file with your subscription-specific values:

```bash
# Edit dev configuration
vi environments/dev.tfvars
```

At minimum, update:
- `subscription_id` — your Azure subscription ID
- `location` — your preferred Azure region
- `naming_prefix` — your organization abbreviation (2–10 chars)

Repeat for `environments/staging.tfvars` and `environments/production.tfvars`.

### Backend Configuration

Edit each backend config with your state storage details:

```bash
vi backend-config/dev.hcl
```

Update:
- `resource_group_name` — resource group for state storage
- `storage_account_name` — globally unique storage account name
- `container_name` — leave as default or customize

Repeat for `backend-config/staging.hcl` and `backend-config/production.hcl`.

## Step 3: Set Up Azure Identity

Follow [docs/identity-setup.md](identity-setup.md) to create:
- One service principal per environment
- OIDC Workload Identity Federation credentials
- Least-privilege RBAC role assignments

## Step 4: Initialize State Backend

Run the initialization script for your first environment:

```bash
./scripts/init-backend.sh dev
```

This creates the Azure Storage Account, blob container, enables versioning,
and runs `tofu init` with the backend configuration.

## Step 5: Verify the Setup

Run a plan to confirm everything is configured correctly:

```bash
tofu plan -var-file=environments/dev.tfvars
```

The plan should complete with no errors and show the baseline resources
to be created (resource group, networking, identity, key vault, storage).

## Step 6: Configure GitHub

Follow [docs/github-setup.md](github-setup.md) to configure:
- Branch protection rules on `dev`, `staging`, `production`
- GitHub environments with required reviewers
- Environment secrets for OIDC authentication

## Step 7: Create Environment Branches

```bash
git checkout -b dev && git push -u origin dev
git checkout -b staging && git push -u origin staging
git checkout -b production && git push -u origin production
```

## Step 8: Apply Baseline Infrastructure

Merge your initial configuration to the `dev` branch via a pull request.
The `apply` workflow will provision the baseline resources.

## Next Steps

- Read [docs/making-changes.md](making-changes.md) for the PR workflow
- Read [docs/state-recovery.md](state-recovery.md) for recovery procedures
- Read [docs/destroying-resources.md](destroying-resources.md) for teardown
