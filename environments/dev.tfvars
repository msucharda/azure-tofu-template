# Environment: dev
# Usage: tofu plan -var-file=environments/dev.tfvars

subscription_id = "babf7774-ca75-4b69-83d0-18d124676548"

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
