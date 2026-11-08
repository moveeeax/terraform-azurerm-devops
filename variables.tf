variable "name" {
  description = "Base name used to derive the resource group name for the deployment/pipeline state."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._()-]{0,79}$", var.name))
    error_message = "The name must be 1-80 characters of letters, digits, '.', '_', '-', '(' or ')' and must start with a letter or digit."
  }
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "The location must not be empty."
  }
}

variable "storage_account_name" {
  description = "Globally unique name of the storage account holding pipeline/Terraform state. Must be 3-24 lowercase alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "The storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "state_container_name" {
  description = "Name of the blob container that stores Terraform/pipeline state."
  type        = string
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])$", var.state_container_name)) && !can(regex("--", var.state_container_name))
    error_message = "The state_container_name must be 3-63 characters of lowercase letters, digits and single hyphens, starting and ending with a letter or digit."
  }
}

variable "account_replication_type" {
  description = "Replication type of the storage account. One of LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "The account_replication_type must be one of LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the state storage account is reachable from the public internet. Set to false when the account is reached over a private endpoint or from a service-endpoint-enabled subnet."
  type        = bool
  default     = true
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days deleted blobs and containers are retained and can be restored. State files are the highest-value object in this account, so soft delete is enabled by default. Must be between 1 and 365."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_retention_days >= 1 && var.blob_soft_delete_retention_days <= 365
    error_message = "The blob_soft_delete_retention_days must be between 1 and 365."
  }
}

variable "shared_access_key_enabled" {
  description = "Whether the state storage account accepts requests authorised with the account access key. Defaults to true (the provider default) because disabling it breaks every backend and pipeline that still uses the key. Set to false once all callers use Entra ID (use_azuread_auth = true) and the provider managing this module sets storage_use_azuread = true."
  type        = bool
  default     = true
}

variable "state_writer_principal_ids" {
  description = "Map of static label => Entra ID object ID of a principal (user, group, service principal or managed identity) granted Storage Blob Data Contributor on the state container. Keyed by label so object IDs that are only known after apply still work in for_each."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.state_writer_principal_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v))
    ])
    error_message = "Every value in state_writer_principal_ids must be an Entra ID object ID (a GUID)."
  }
}

variable "state_reader_principal_ids" {
  description = "Map of static label => Entra ID object ID of a principal granted Storage Blob Data Reader on the state container, e.g. for plan-only pipelines."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.state_reader_principal_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v))
    ])
    error_message = "Every value in state_reader_principal_ids must be an Entra ID object ID (a GUID)."
  }
}

variable "backend_use_azuread_auth" {
  description = "Value of use_azuread_auth in the backend_config and backend_config_hcl outputs. Ignored (always true) when shared_access_key_enabled is false. Leave false when the backend authenticates with the storage account key (the azurerm backend fetches it with your ARM credentials); set to true when the identity running Terraform holds a Storage Blob Data role on the state container. Only affects the outputs, not any resource."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}
