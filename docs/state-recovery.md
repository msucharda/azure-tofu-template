# State Recovery

Comprehensive runbook for diagnosing and recovering from OpenTofu state issues.

## Table of Contents

1. [Diagnosing State Issues](#diagnosing-state-issues)
2. [Restoring from Blob Version Backup](#restoring-from-blob-version-backup)
3. [Importing Existing Resources](#importing-existing-resources)
4. [Resolving Drift](#resolving-drift)
5. [State Move Operations](#state-move-operations)
6. [Emergency Procedures](#emergency-procedures)
7. [Troubleshooting Backend Connectivity](#troubleshooting-backend-connectivity)

## Diagnosing State Issues

### Symptoms

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| `tofu plan` shows resources to create that already exist | State lost or corrupted | Restore from backup or import |
| `tofu plan` shows changes you didn't make | Configuration drift | Reconcile with apply or manual fix |
| State lock error | Concurrent operation or stale lock | Break lock after investigation |
| Backend authentication error | Expired credentials or RBAC change | Check OIDC and RBAC config |

### Quick Diagnosis

```bash
# Check current state
tofu show

# Compare state with live infrastructure
./scripts/drift-detect.sh <env>

# List resources in state
tofu state list
```

## Restoring from Blob Version Backup

Azure Blob versioning automatically creates a version snapshot on every state
write. Use the recovery script:

```bash
./scripts/state-recover.sh <env>
```

The script will:
1. List all available blob versions with timestamps
2. Prompt you to select a version
3. Restore the selected version as the current state
4. Run `tofu plan` to verify the recovery

### Manual Restore

If the script fails, restore manually:

```bash
# List blob versions
az storage blob list \
  --account-name <sa_name> \
  --container-name <container> \
  --include v \
  --prefix terraform.tfstate \
  --auth-mode login \
  --output table

# Download a specific version
az storage blob download \
  --account-name <sa_name> \
  --container-name <container> \
  --name terraform.tfstate \
  --version-id <version_id> \
  --file terraform.tfstate.backup \
  --auth-mode login

# Upload as current
az storage blob upload \
  --account-name <sa_name> \
  --container-name <container> \
  --name terraform.tfstate \
  --file terraform.tfstate.backup \
  --auth-mode login \
  --overwrite
```

## Importing Existing Resources

When resources exist in Azure but not in state:

```bash
./scripts/state-import.sh <env> <resource_address> <azure_resource_id>
```

### Finding the Resource Address

The resource address is the OpenTofu path. For resources inside modules:

```
module.resource_group.module.resource_group.azurerm_resource_group.this[0]
module.networking[0].module.virtual_network.azurerm_virtual_network.this[0]
module.key_vault[0].module.key_vault.azurerm_key_vault.this[0]
```

### Finding the Azure Resource ID

```bash
# List resources in a resource group
az resource list --resource-group <rg-name> --output table

# Get specific resource ID
az resource show --name <name> --resource-group <rg> --resource-type <type> --query id -o tsv
```

## Resolving Drift

Drift occurs when infrastructure changes happen outside OpenTofu.

```bash
# Detect drift
./scripts/drift-detect.sh <env>
```

### Resolution Options

1. **Accept drift** — update your config to match reality:
   ```bash
   # Edit .tf files to match the current state
   tofu plan -var-file=environments/<env>.tfvars  # Should show no changes
   ```

2. **Revert drift** — apply your config to override manual changes:
   ```bash
   tofu apply -var-file=environments/<env>.tfvars
   ```

3. **Selective reconciliation** — target specific resources:
   ```bash
   tofu apply -target=module.networking -var-file=environments/<env>.tfvars
   ```

## State Move Operations

When refactoring module structure:

```bash
# Move a resource to a new address
tofu state mv 'module.old_name' 'module.new_name'

# Remove a resource from state (without destroying it)
tofu state rm 'module.resource.azurerm_type.name'

# Always plan after state operations
tofu plan -var-file=environments/<env>.tfvars
```

## Emergency Procedures

### State File Deleted

1. **Don't panic** — blob versioning has backups
2. Run `./scripts/state-recover.sh <env>`
3. Select the most recent version before deletion
4. Verify with `tofu plan`

### State File Corrupted

1. Download the corrupted state: `tofu state pull > corrupted.tfstate`
2. Restore from the last known good version:
   `./scripts/state-recover.sh <env>`
3. Compare states to identify the corruption

### State Lock Stuck

```bash
# Check who holds the lock
tofu force-unlock <lock_id>
```

> ⚠️ Only force-unlock if you're certain no other operation is running.

### Complete State Loss (No Blob Versions)

If all blob versions are gone (extremely rare):

1. Create an empty state: `tofu init -backend-config=backend-config/<env>.hcl`
2. Import each resource manually:
   ```bash
   ./scripts/state-import.sh <env> <address> <azure_id>
   ```
3. Verify with `tofu plan` — aim for zero changes

## Troubleshooting Backend Connectivity

### Authentication Errors

```bash
# Verify Azure CLI login
az account show

# Check RBAC on storage account
az role assignment list \
  --assignee <service_principal_id> \
  --scope <storage_account_resource_id>

# Test storage access directly
az storage blob list \
  --account-name <sa_name> \
  --container-name <container> \
  --auth-mode login
```

### Network Connectivity

```bash
# Check storage account firewall
az storage account show \
  --name <sa_name> \
  --query networkRuleSet

# If using private endpoints, verify DNS resolution
nslookup <sa_name>.blob.core.windows.net
```

### Common Backend Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Error acquiring the state lock` | Concurrent operation | Wait or force-unlock |
| `403 Forbidden` | Missing RBAC role | Assign Storage Blob Data Contributor |
| `404 Not Found` | Container doesn't exist | Run `init-backend.sh` |
| `AuthorizationFailure` | Wrong subscription context | Check `az account show` |
