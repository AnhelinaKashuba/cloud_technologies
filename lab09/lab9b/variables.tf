variable "location" {
  description = "Регіон Azure для ресурсів"
  default     = "East US"
}

variable "resource_group_name" {
  description = "Назва групи ресурсів"
  default     = "az104-rg9" 
}

variable "container_name" {
  description = "Унікальне ім'я контейнера"
  default     = "az104-c1"
}

variable "dns_name_label" {
  description = "Унікальна мітка DNS для публічного доступу"
   default     = "aci-helloworld-anhelina"
}