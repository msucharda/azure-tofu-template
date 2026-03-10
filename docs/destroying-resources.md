# Destroying Resources

Safe teardown procedures for controlled infrastructure destruction.

## When to Destroy

- Decommissioning a subscription or environment
- Cleaning up after testing or proof-of-concept work
- Rebuilding infrastructure from scratch (e.g., after major refactoring)

## Pre-Destroy Checklist

Before triggering destruction:

- [ ] **Backup state file**: Download the current state from Azure Storage
- [ ] **Confirm scope**: Verify you're targeting the correct environment
- [ ] **Check dependencies**: Ensure no external systems depend on these resources
- [ ] **Review deletion protection**: Some resources may have locks or protection
- [ ] **Notify stakeholders**: Inform teams that depend on the environment
- [ ] **Document reason**: Record why the destruction is happening

## Triggering the Destroy Workflow

1. Navigate to **Actions → Destroy** in GitHub
2. Click **"Run workflow"**
3. Select the target **environment** (dev/staging/production)
4. Type **`DESTROY`** in the confirmation field (exact match required)
5. Click **"Run workflow"**

The workflow:

1. Validates your confirmation text
2. Runs `tofu plan -destroy` and posts the plan as a step summary
3. Requires **manual approval** via the GitHub environment gate
4. Executes `tofu apply -destroy` after approval

## After Destruction

1. **Verify cleanup**: Check the Azure Portal to confirm resources are gone
2. **State check**: The state file will reflect an empty state
3. **Blob versioning**: The previous state is preserved as a blob version
   for recovery if needed

## Handling Resources with Deletion Protection

Some resources may have deletion protection enabled:

- **Key Vault**: Has soft-delete and purge protection. After destruction,
  the vault enters soft-deleted state. Purge after the retention period
  or use `az keyvault purge` if purge protection allows it.
- **Resource Group**: If `prevent_deletion_if_contains_resources` is true
  in the provider config, you must destroy child resources first.
- **Storage Account**: Blob versioning preserves data even after container
  deletion. The storage account itself will be deleted.

## Partial Destruction

To destroy specific resources without tearing down the entire environment:

```bash
# Target specific resources
tofu plan -destroy \
  -target=module.storage \
  -var-file=environments/dev.tfvars

# Review the plan, then apply
tofu apply -destroy \
  -target=module.storage \
  -var-file=environments/dev.tfvars
```

⚠️ **Warning**: Targeted destroys can leave orphaned dependencies.
Always run a full `tofu plan` afterward to verify state consistency.

## Recovery After Accidental Destruction

If resources were destroyed by mistake:

1. Restore the pre-destroy state: `./scripts/state-recover.sh <env>`
2. Re-import existing resources: `./scripts/state-import.sh <env> <addr> <id>`
3. See [state-recovery.md](state-recovery.md) for detailed procedures
