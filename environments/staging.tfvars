# Environment: staging
# Usage: tofu plan -var-file=environments/staging.tfvars

subscription_id = "00000000-0000-0000-0000-000000000000" # REPLACE with your staging subscription ID

location      = "westeurope"
environment   = "staging"
naming_prefix = "contoso"

tags = {
  environment = "staging"
  cost-center = "engineering"
}

# Module toggles
enable_networking = true
enable_identity   = true
enable_key_vault  = true
enable_storage    = true
