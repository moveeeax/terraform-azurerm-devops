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

run "backend_config_points_at_the_state_container" {
  assert {
    condition = output.backend_config == {
      subscription_id      = "00000000-0000-0000-0000-000000000000"
      resource_group_name  = "platform-devops-rg"
      storage_account_name = "platformdevopssa01"
      container_name       = "tfstate"
      use_azuread_auth     = false
    }
    error_message = "backend_config must name the module's subscription, resource group, account and container, with key-based auth by default."
  }

  assert {
    condition     = strcontains(output.backend_config_hcl, "container_name       = \"tfstate\"\n")
    error_message = "backend_config_hcl must render the container name as an HCL string."
  }

  assert {
    condition     = strcontains(output.backend_config_hcl, "use_azuread_auth     = false\n")
    error_message = "backend_config_hcl must render use_azuread_auth as a bare boolean."
  }
}

run "backend_config_can_select_entra_id_auth" {
  variables {
    backend_use_azuread_auth = true
    state_container_name     = "pipeline-state"
  }

  assert {
    condition     = output.backend_config.use_azuread_auth == true && output.backend_config.container_name == "pipeline-state"
    error_message = "backend_config must follow backend_use_azuread_auth and state_container_name."
  }

  assert {
    condition     = strcontains(output.backend_config_hcl, "use_azuread_auth     = true\n")
    error_message = "backend_config_hcl must follow backend_use_azuread_auth."
  }
}

run "defaults_keep_shared_keys_and_grant_nothing" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == true
    error_message = "Shared key access must stay enabled by default; disabling it breaks key-based backends on upgrade."
  }

  assert {
    condition     = length(azurerm_role_assignment.state_writer) == 0 && length(azurerm_role_assignment.state_reader) == 0
    error_message = "No role assignments may be planned unless principals are supplied."
  }
}

run "grants_container_scoped_entra_id_roles" {
  variables {
    state_writer_principal_ids = {
      pipeline = "11111111-1111-1111-1111-111111111111"
    }
    state_reader_principal_ids = {
      plan_only = "22222222-2222-2222-2222-222222222222"
    }
  }

  assert {
    condition     = azurerm_role_assignment.state_writer["pipeline"].role_definition_name == "Storage Blob Data Contributor"
    error_message = "State writers must get Storage Blob Data Contributor."
  }

  assert {
    condition     = azurerm_role_assignment.state_reader["plan_only"].role_definition_name == "Storage Blob Data Reader"
    error_message = "State readers must get Storage Blob Data Reader."
  }

  assert {
    condition     = azurerm_role_assignment.state_writer["pipeline"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-devops-rg/providers/Microsoft.Storage/storageAccounts/mockstate01/blobServices/default/containers/tfstate"
    error_message = "Role assignments must be scoped to the state container, not the account."
  }

  assert {
    condition     = azurerm_role_assignment.state_reader["plan_only"].scope == output.state_container_resource_manager_id
    error_message = "state_container_resource_manager_id must equal the role assignment scope."
  }

  assert {
    condition     = output.backend_config.use_azuread_auth == false
    error_message = "Granting roles alone must not change the backend auth mode while shared keys are enabled."
  }
}

run "disabling_shared_keys_forces_entra_id_backend_auth" {
  variables {
    shared_access_key_enabled = false
  }

  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == false
    error_message = "shared_access_key_enabled = false must reach the storage account."
  }

  assert {
    condition     = output.backend_config.use_azuread_auth == true
    error_message = "Without shared keys the backend config must use Entra ID auth."
  }

  assert {
    condition     = strcontains(output.backend_config_hcl, "use_azuread_auth     = true\n")
    error_message = "backend_config_hcl must use Entra ID auth when shared keys are disabled."
  }
}

run "rejects_non_guid_writer_principal" {
  command = plan

  variables {
    state_writer_principal_ids = {
      pipeline = "my-service-principal"
    }
  }

  expect_failures = [var.state_writer_principal_ids]
}

run "rejects_non_guid_reader_principal" {
  command = plan

  variables {
    state_reader_principal_ids = {
      plan_only = "user@example.com"
    }
  }

  expect_failures = [var.state_reader_principal_ids]
}
