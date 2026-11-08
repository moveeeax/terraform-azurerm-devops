output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.this.name
}

output "storage_account_id" {
  description = "ID of the state storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the state storage account."
  value       = azurerm_storage_account.this.name
}

output "state_container_name" {
  description = "Name of the state blob container."
  value       = azurerm_storage_container.state.name
}

output "backend_config" {
  description = "Map of azurerm backend settings for the state container: subscription_id, resource_group_name, storage_account_name, container_name and use_azuread_auth. Contains no credentials."
  value       = local.backend_config
}

output "backend_config_hcl" {
  description = "The backend_config map rendered as a partial backend configuration file. Write it with `terraform output -raw backend_config_hcl > backend.hcl` and pass it to `terraform init -backend-config=backend.hcl`."
  value       = <<-EOT
    subscription_id      = "${local.backend_config.subscription_id}"
    resource_group_name  = "${local.backend_config.resource_group_name}"
    storage_account_name = "${local.backend_config.storage_account_name}"
    container_name       = "${local.backend_config.container_name}"
    use_azuread_auth     = ${local.backend_config.use_azuread_auth}
  EOT
}
