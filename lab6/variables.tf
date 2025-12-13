variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}