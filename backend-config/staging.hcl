# Backend configuration for the staging environment.
# Usage: tofu init -backend-config=backend-config/staging.hcl

resource_group_name  = "rg-tfstate-staging"
storage_account_name = "sttfstatestaging"
container_name       = "tfstate-staging"
key                  = "terraform.tfstate"
