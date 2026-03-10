# GitHub Setup: Branch Protection & Environments

This guide documents the required GitHub configuration for the
PR-driven workflow, including branch protection rules, GitHub
environments, and environment secrets for OIDC authentication.

## Prerequisites

- GitHub repository administrator access
- Service principal client IDs from [identity-setup.md](identity-setup.md)
- Azure tenant ID and subscription IDs

## Step 1: Create GitHub Environments

Navigate to **Settings → Environments** and create three environments:

### dev
- **Required reviewers**: 1 reviewer
- **Deployment branches**: `dev` branch only

### staging
- **Required reviewers**: 1 reviewer
- **Deployment branches**: `staging` branch only

### production
- **Required reviewers**: 2 reviewers
- **Deployment branches**: `production` branch only
- **Wait timer**: Optional — add a delay for production deployments

## Step 2: Configure Environment Secrets

For **each** environment (`dev`, `staging`, `production`), add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | Service principal client ID | From identity-setup.md Step 5 |
| `AZURE_TENANT_ID` | Azure AD tenant ID | Same for all environments |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID | May differ per environment |

Navigate to **Settings → Environments → \<env\> → Environment secrets**.

> **Note**: These are environment-scoped secrets, not repository secrets.
> Each environment uses its own service principal for least-privilege isolation.

## Step 3: Configure Branch Protection Rules

Navigate to **Settings → Branches** and add protection rules for each
environment branch.

### Rule: `dev`

- [x] **Require a pull request before merging**
  - Required approvals: **1**
- [x] **Require status checks to pass before merging**
  - Required checks:
    - `Validate`
    - `Lint`
    - `Security Scan`
- [x] **Require branches to be up to date before merging**
- [x] **Do not allow bypassing the above settings**
- [ ] Include administrators (recommended: enabled)

### Rule: `staging`

Same as `dev`.

### Rule: `production`

- [x] **Require a pull request before merging**
  - Required approvals: **2**
- [x] **Require status checks to pass before merging**
  - Required checks:
    - `Validate`
    - `Lint`
    - `Security Scan`
- [x] **Require branches to be up to date before merging**
- [x] **Require review from code owners** (if CODEOWNERS file exists)
- [x] **Do not allow bypassing the above settings**
- [x] **Include administrators**

## Step 4: Verify Configuration

1. Create a test feature branch from `dev`
2. Make a trivial change (e.g., add a comment to a tfvars file)
3. Push and open a PR targeting `dev`
4. Verify:
   - The `pr-validate` workflow triggers
   - The PR cannot be merged without passing status checks
   - The PR requires at least 1 approval
5. After approval and merge, verify:
   - The `apply` workflow triggers on the `dev` branch
   - OIDC authentication succeeds

## Troubleshooting

### Workflow doesn't trigger on PR
- Check that branch protection references the correct workflow job names
- Verify the PR targets an environment branch (dev/staging/production)

### OIDC authentication fails
- Verify the federated credential subject matches the branch/PR pattern
- Check that environment secrets are set correctly
- Ensure the service principal has the required RBAC roles

### Status checks not appearing
- Status checks only appear after the workflow has run at least once
- You may need to manually type the check name the first time
