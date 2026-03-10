# Backend configuration for the production environment.
# Usage: tofu init -backend-config=backend-config/production.hcl

resource_group_name  = "rg-tfstate-production"
storage_account_name = "sttfstateprod"
container_name       = "tfstate-production"
key                  = "terraform.tfstate"
