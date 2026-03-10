# Making Changes: PR Workflow Guide

All infrastructure changes follow a GitFlow PR-driven workflow. Direct pushes
to environment branches (`dev`, `staging`, `production`) are prohibited.

## Workflow Overview

```
feature branch → Pull Request → Review → Merge → Auto-Apply
```

## Step-by-Step

### 1. Create a Feature Branch

Branch from the target environment branch:

```bash
# For a change targeting dev
git checkout dev
git pull origin dev
git checkout -b feature/add-database

# For a hotfix targeting production
git checkout production
git pull origin production
git checkout -b hotfix/fix-nsg-rule
```

### 2. Make Your Changes

Edit the relevant files:

- **New resource**: Add or modify a module in `modules/`, reference it in `main.tf`,
  add variables to `variables.tf` and values to `environments/*.tfvars`
- **Configuration change**: Update values in `environments/<env>.tfvars`
- **Module update**: Modify files in the target `modules/<name>/` directory

### 3. Test Locally

```bash
# Format check
tofu fmt -recursive -check

# Validate
tofu validate

# Plan against the target environment
tofu plan -var-file=environments/dev.tfvars
```

### 4. Push and Open a Pull Request

```bash
git add .
git commit -m "feat: add database module for dev environment"
git push -u origin feature/add-database
```

Open a PR targeting the environment branch (e.g., `dev`).

### 5. Review Automated Results

The `pr-validate` workflow runs automatically and posts a comment with:

- **Format check** — whether all files are properly formatted
- **Validate** — whether the configuration is syntactically valid
- **Plan output** — what resources will be created, changed, or destroyed
- **Lint results** — tflint findings for Azure best practices
- **Security scan** — checkov and trivy findings

Review the plan output carefully. Verify:
- Only expected resources are being modified
- No unintended deletions
- Security scan has no critical findings

### 6. Get Approvals

| Environment | Required Approvals |
|-------------|--------------------|
| dev         | 1                  |
| staging     | 1                  |
| production  | 2                  |

### 7. Merge

After approval, merge the PR. The `apply` workflow triggers automatically and:

1. Initializes OpenTofu with the environment backend
2. Runs a fresh plan
3. Applies the changes (auto-approve for dev/staging, manual gate for production)

### 8. Verify

After the apply workflow completes:

1. Check the workflow run in GitHub Actions for success
2. Verify resources in the Azure Portal or via CLI
3. Run drift detection to confirm state matches reality:

```bash
./scripts/drift-detect.sh dev
```

## Promoting Changes

To promote a change from dev → staging → production:

1. Open a PR from `dev` → `staging`
2. Review the plan (it will show the diff for staging)
3. Approve and merge
4. Repeat: PR from `staging` → `production`

## Emergency Hotfixes

For critical production fixes:

1. Branch directly from `production`
2. Make the minimal fix
3. Open a PR to `production` with expedited review
4. After merge and apply, backport to `staging` and `dev`
