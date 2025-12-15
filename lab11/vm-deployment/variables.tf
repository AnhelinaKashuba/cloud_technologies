variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}
