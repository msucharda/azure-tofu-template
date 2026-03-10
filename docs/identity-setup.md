# Identity Setup: OIDC Workload Identity Federation

This guide documents how to set up Azure AD service principals with
OIDC Workload Identity Federation for GitHub Actions CI/CD pipelines.

## Overview

Each environment (`dev`, `staging`, `production`) gets its own:
- Azure AD App Registration
- Service Principal
- Federated Credential scoped to the environment branch
- RBAC role assignment with least-privilege permissions

This eliminates stored client secrets — GitHub Actions authenticates
via OIDC token exchange.

## Prerequisites

- Azure AD Global Administrator or Application Administrator role
- Azure CLI (`az`) authenticated with sufficient permissions
- The GitHub repository URL (e.g., `<org>/<repo>`)

## Step 1: Create App Registration Per Environment

```bash
# Create app registration for each environment
for ENV in dev staging production; do
  az ad app create \
    --display-name "sp-opentofu-${ENV}" \
    --sign-in-audience AzureADMyOrg
done
```

Note the `appId` (client ID) from each command output.

## Step 2: Create Service Principals

```bash
for ENV in dev staging production; do
  APP_ID=$(az ad app list --display-name "sp-opentofu-${ENV}" --query "[0].appId" -o tsv)
  az ad sp create --id "$APP_ID"
done
```

## Step 3: Configure Federated Credentials

Each federated credential is scoped to the specific environment branch:

```bash
REPO="<org>/<repo>"  # Replace with your GitHub org/repo

for ENV in dev staging production; do
  APP_ID=$(az ad app list --display-name "sp-opentofu-${ENV}" --query "[0].appId" -o tsv)
  OBJECT_ID=$(az ad app show --id "$APP_ID" --query "id" -o tsv)

  az ad app federated-credential create \
    --id "$OBJECT_ID" \
    --parameters "{
      \"name\": \"github-${ENV}\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:${REPO}:ref:refs/heads/${ENV}\",
      \"audiences\": [\"api://AzureADTokenExchange\"],
      \"description\": \"GitHub Actions OIDC for ${ENV} branch\"
    }"
done
```

**Important**: Also add federated credentials for pull requests targeting each branch:

```bash
for ENV in dev staging production; do
  APP_ID=$(az ad app list --display-name "sp-opentofu-${ENV}" --query "[0].appId" -o tsv)
  OBJECT_ID=$(az ad app show --id "$APP_ID" --query "id" -o tsv)

  az ad app federated-credential create \
    --id "$OBJECT_ID" \
    --parameters "{
      \"name\": \"github-${ENV}-pr\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:${REPO}:pull_request\",
      \"audiences\": [\"api://AzureADTokenExchange\"],
      \"description\": \"GitHub Actions OIDC for PRs targeting ${ENV}\"
    }"
done
```

## Step 4: Assign RBAC Roles

Assign least-privilege roles. The recommended baseline:

| Role | Scope | Purpose |
|------|-------|---------|
| Contributor | Subscription | Create/manage resources |
| Storage Blob Data Contributor | State storage account | Read/write state files |
| User Access Administrator | Subscription | Manage RBAC (if needed) |

```bash
for ENV in dev staging production; do
  APP_ID=$(az ad app list --display-name "sp-opentofu-${ENV}" --query "[0].appId" -o tsv)
  SP_ID=$(az ad sp show --id "$APP_ID" --query "id" -o tsv)
  SUB_ID="<subscription-id>"  # Replace per environment

  # Contributor on subscription
  az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Contributor" \
    --scope "/subscriptions/${SUB_ID}"

  # Storage Blob Data Contributor on state storage
  SA_RG="rg-tfstate-${ENV}"
  SA_NAME="sttfstate${ENV}"
  az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/${SUB_ID}/resourceGroups/${SA_RG}/providers/Microsoft.Storage/storageAccounts/${SA_NAME}"
done
```

> **Security note**: Avoid assigning `Owner` unless absolutely necessary.
> If your template needs to manage RBAC assignments, use `User Access Administrator`
> scoped to specific resource groups rather than the full subscription.

## Step 5: Record Client IDs

Store the client IDs — you'll need them for GitHub environment secrets:

```bash
for ENV in dev staging production; do
  APP_ID=$(az ad app list --display-name "sp-opentofu-${ENV}" --query "[0].appId" -o tsv)
  echo "${ENV}: ${APP_ID}"
done
```

## Rotation and Maintenance

- **No secret rotation needed** — OIDC uses short-lived tokens
- **Audit**: Periodically review role assignments with
  `az role assignment list --assignee <sp-id>`
- **Decommission**: Remove the app registration and all role assignments
  when an environment is retired
