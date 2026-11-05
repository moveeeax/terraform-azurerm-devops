terraform {
  # The module itself works on Terraform >= 1.5.
  # The test suite in tests/ uses `mock_provider`, which needs Terraform
  # >= 1.7 (or OpenTofu >= 1.7). That is a test-only requirement and is
  # deliberately not encoded here, so consumers are not forced to upgrade.
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # azurerm_storage_container.storage_account_id was only added in
      # 4.9.0; on anything older this module fails to validate. Ceiling:
      # validated and tested on 5.x; 6.0 has not been vetted.
      version = ">= 4.9, < 6.0"
    }
  }
}
