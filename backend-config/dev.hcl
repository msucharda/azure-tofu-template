# Backend configuration for the dev environment.
# Usage: tofu init -backend-config=backend-config/dev.hcl

resource_group_name  = "rg-tfstate-dev"
storage_account_name = "sttfstatedev"
container_name       = "tfstate-dev"
key                  = "terraform.tfstate"
