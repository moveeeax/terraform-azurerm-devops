# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or
# OpenTofu >= 1.7). The module itself still supports >= 1.5 — see versions.tf.
#
# Run with: terraform init -backend=false && terraform test

mock_provider "azurerm" {
  # azurerm_storage_container parses the storage account ID at plan time, so
  # the generated mock value has to be a well-formed (but entirely fictional)
  # resource ID rather than a random string.
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-devops-rg/providers/Microsoft.Storage/storageAccounts/mockstate01"
    }
  }
}

variables {
  name                 = "platform"
  location             = "eastus"
  storage_account_name = "platformdevopssa01"
}

run "state_account_is_not_publicly_exposed" {
  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "The state storage account must not allow anonymous public access to nested containers or blobs."
  }

  assert {
    condition     = azurerm_storage_container.state.container_access_type == "private"
    error_message = "The state container must be private."
  }
}

run "transport_and_encryption_defaults_are_hardened" {
  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "The state storage account must require TLS 1.2 or newer."
  }

  assert {
    condition     = azurerm_storage_account.this.https_traffic_only_enabled == true
    error_message = "The state storage account must reject plaintext HTTP."
  }
}

run "state_is_recoverable_by_default" {
  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be enabled so state file overwrites are recoverable."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Deleted state blobs must be retained for 7 days by default."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].container_delete_retention_policy[0].days == 7
    error_message = "A deleted state container must be retained for 7 days by default."
  }
}

run "public_network_access_can_be_locked_down" {
  variables {
    public_network_access_enabled = false
  }

  assert {
    condition     = azurerm_storage_account.this.public_network_access_enabled == false
    error_message = "public_network_access_enabled must be honoured when set to false."
  }
}

run "resource_group_name_is_derived_from_name" {
  assert {
    condition     = azurerm_resource_group.this.name == "platform-devops-rg"
    error_message = "The resource group name must be derived as <name>-devops-rg."
  }
}

run "rejects_invalid_replication_type" {
  command = plan

  variables {
    account_replication_type = "SuperDuperRedundant"
  }

  expect_failures = [var.account_replication_type]
}

run "rejects_invalid_storage_account_name" {
  command = plan

  variables {
    storage_account_name = "Not-A-Valid-Name"
  }

  expect_failures = [var.storage_account_name]
}

run "rejects_invalid_container_name" {
  command = plan

  variables {
    state_container_name = "TFState"
  }

  expect_failures = [var.state_container_name]
}

run "rejects_out_of_range_soft_delete_retention" {
  command = plan

  variables {
    blob_soft_delete_retention_days = 0
  }

  expect_failures = [var.blob_soft_delete_retention_days]
}

run "rejects_empty_location" {
  command = plan

  variables {
    location = "   "
  }

  expect_failures = [var.location]
}
