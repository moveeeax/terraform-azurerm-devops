variable "name" {
  description = "Base name used to derive the resource group name for the deployment/pipeline state."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string
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
}

variable "account_replication_type" {
  description = "Replication type of the storage account (e.g. LRS, GRS, ZRS)."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}
