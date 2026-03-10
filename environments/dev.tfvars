# Environment: dev
# Usage: tofu plan -var-file=environments/dev.tfvars

subscription_id = "00000000-0000-0000-0000-000000000000" # REPLACE with your dev subscription ID

location      = "westeurope"
environment   = "dev"
naming_prefix = "contoso"

tags = {
  environment = "dev"
  cost-center = "engineering"
}

# Module toggles
enable_networking = true
enable_identity   = true
enable_key_vault  = true
enable_storage    = true
