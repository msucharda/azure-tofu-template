# Environment: production
# Usage: tofu plan -var-file=environments/production.tfvars

subscription_id = "00000000-0000-0000-0000-000000000000" # REPLACE with your production subscription ID

location      = "westeurope"
environment   = "production"
naming_prefix = "contoso"

tags = {
  environment = "production"
  cost-center = "engineering"
}

# Module toggles
enable_networking = true
enable_identity   = true
enable_key_vault  = true
enable_storage    = true
