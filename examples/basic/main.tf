terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9, < 6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "devops" {
  source = "../.."

  name                 = "example"
  location             = "eastus"
  storage_account_name = "exampledevopssa01"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "storage_account_id" {
  value = module.devops.storage_account_id
}

output "state_container_name" {
  value = module.devops.state_container_name
}

# terraform output -raw backend_hcl > backend.hcl
output "backend_hcl" {
  value = module.devops.backend_config_hcl
}
