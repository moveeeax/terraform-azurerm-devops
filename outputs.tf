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
