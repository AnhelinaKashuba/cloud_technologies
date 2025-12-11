variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group for the lab"
  type        = string
  default     = "az104-rg4"
}

variable "public_dns_zone_name" {
  description = "Public DNS zone name"
  type        = string
  default     = "contoso.com"
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name"
  type        = string
  default     = "private.contoso.com"
}
