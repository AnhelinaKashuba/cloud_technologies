# Основні налаштування
variable "resource_group_name" {
  type        = string
  default     = "az104-rg6"
  description = "Назва групи ресурсів для лабораторної роботи 6"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Регіон Azure (East US)"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Ім'я адміністратора для віртуальних машин"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Пароль адміністратора (задається в terraform.tfvars)"
}

# Налаштування віртуальної мережі
variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.60.0.0/20"]
  description = "Адресний простір віртуальної мережі"
}

variable "subnets" {
  type = map(object({
    name   = string
    prefix = string
  }))
  default = {
    "subnet0" = {
      name   = "subnet0"
      prefix = "10.60.0.0/24"
    }
    "subnet1" = {
      name   = "subnet1"
      prefix = "10.60.1.0/24"
    }
    "subnet2" = {
      name   = "subnet2"
      prefix = "10.60.2.0/24"
    }
    "subnet-appgw" = {
      name   = "subnet-appgw"
      prefix = "10.60.3.224/27"
    }
  }
}

# Налаштування віртуальних машин
variable "vm_names" {
  type        = list(string)
  default     = ["az104-06-vm0", "az104-06-vm1", "az104-06-vm2"]
  description = "Назви трьох віртуальних машин"
}

variable "vm_size" {
  type        = string
  default     = "Standard_DC1ds_v3" 
  description = "Розмір віртуальної машини (мінімум 2 ядра)"
}

# Налаштування Load Balancer
variable "load_balancer_name" {
  type        = string
  default     = "az104-lb"
  description = "Назва Load Balancer"
}

variable "lb_frontend_ip_name" {
  type        = string
  default     = "az104-fe"
  description = "Назва конфігурації фронтенд IP для Load Balancer"
}

# Налаштування Application Gateway
variable "app_gateway_name" {
  type        = string
  default     = "az104-appgw"
  description = "Назва Application Gateway"
}

variable "app_gateway_sku" {
  type        = string
  default     = "Standard_v2"
  description = "SKU Application Gateway"
}