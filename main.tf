resource "azurerm_resource_group" "this" {
  name     = "${var.name}-devops-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = var.account_replication_type
  min_tls_version          = "TLS1_2"

  # The provider defaults this to true, which lets anyone with write access
  # to the account flip a container (or an individual blob) to anonymous
  # public read. An account holding Terraform state must never allow that,
  # so the capability is switched off at the account level.
  allow_nested_items_to_be_public = false

  https_traffic_only_enabled    = true
  public_network_access_enabled = var.public_network_access_enabled

  # true is the provider default, so existing accounts plan unchanged. Turning
  # it off breaks every backend and pipeline still authenticating with the
  # account key, which is why it is opt-in.
  shared_access_key_enabled = var.shared_access_key_enabled

  blob_properties {
    versioning_enabled = true

    # Versioning alone does not protect against a deleted blob or a deleted
    # container. Soft delete is what makes an accidental `terraform destroy`
    # or a fat-fingered container delete recoverable.
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "state" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

locals {
  # Role assignments target the container, not the account, so a pipeline
  # identity can reach the state and nothing else stored here. Built from the
  # account ID so the scope is always the ARM form of the container ID.
  state_container_scope = "${azurerm_storage_account.this.id}/blobServices/default/containers/${azurerm_storage_container.state.name}"

  # Settings for a `backend "azurerm"` block pointing at the state container.
  # `key` is deliberately absent: it names one state file, so each root module
  # sets its own (e.g. -backend-config="key=app.tfstate").
  backend_config = {
    subscription_id      = split("/", azurerm_storage_account.this.id)[2]
    resource_group_name  = azurerm_resource_group.this.name
    storage_account_name = azurerm_storage_account.this.name
    container_name       = azurerm_storage_container.state.name
    # Without shared keys the backend can only authenticate through Entra ID.
    use_azuread_auth = var.backend_use_azuread_auth || !var.shared_access_key_enabled
  }
}

resource "azurerm_role_assignment" "state_writer" {
  for_each = var.state_writer_principal_ids

  scope                = local.state_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "state_reader" {
  for_each = var.state_reader_principal_ids

  scope                = local.state_container_scope
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
