variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  type    = string
  default = "az104-rg5"
}

variable "admin_username" {
  type    = string
  default = "localadmin"
}

variable "admin_password" {
  description = "Password for Windows VMs. Prefer passing via environment or keyvault."
  type        = string
  sensitive   = true
}
