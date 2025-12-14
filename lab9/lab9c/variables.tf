variable "location" {
  description = "Регіон для розгортання"
  default     = "East US"
}

variable "resource_group_name" {
  description = "Назва існуючої групи ресурсів"
  default     = "az104-rg9"
}

variable "container_app_name" {
  description = "Назва Container App"
  default     = "my-app"
}

variable "environment_name" {
  description = "Назва середовища (Environment) для Container Apps"
  default     = "my-environment"
}