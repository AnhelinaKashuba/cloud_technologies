variable "location" {
  description = "Azure region"
  default     = "West Europe"
}

variable "web_app_name" {
  description = "Name for the web app (must be globally unique)"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "az104-rg9"
}