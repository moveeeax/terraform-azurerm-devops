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

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}
