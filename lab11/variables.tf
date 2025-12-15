variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "email_address" {
  description = "Email for alert notifications"
  type        = string
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}
