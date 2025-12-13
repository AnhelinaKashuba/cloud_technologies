# Основні налаштування
variable "resource_group_name" {
  type        = string
  default     = "az104-rg8"
  description = "Назва групи ресурсів"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Регіон Azure"
}

# Налаштування для звичайних віртуальних машин (Завдання 1-2)
variable "vm_names" {
  type        = list(string)
  default     = ["az104-vm1", "az104-vm2"]
  description = "Назви віртуальних машин"
}

variable "vm_zones" {
  type        = list(string)
  default     = ["3", "3"]
  description = "Зони доступності для віртуальних машин"
}

variable "vm_size" {
  type        = string
  default     = "Standard_DC1ds_v3"
  description = "Розмір віртуальної машини"
}

variable "admin_username" {
  type        = string
  default     = "localadmin"
  description = "Ім'я адміністратора"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Пароль адміністратора (задається в terraform.tfvars)"
}

# Налаштування для диска (Завдання 2)
variable "data_disk_name" {
  type        = string
  default     = "vm1-disk1"
  description = "Назва диску даних"
}

variable "data_disk_size_gb" {
  type        = number
  default     = 32
  description = "Розмір диску даних в ГБ"
}

# Налаштування для масштабованого набору (Завдання 3-4)
variable "vmss_name" {
  type        = string
  default     = "vmss1"
  description = "Назва масштабованого набору"
}

variable "vmss_zones" {
  type        = list(string)
  default     = ["3"]
  description = "Зони доступності для VMSS"
}

variable "vmss_instance_count" {
  type        = number
  default     = 2
  description = "Початкова кількість інстансів"
}

variable "vmss_sku" {
  type        = string
  default     = "Standard_DC1ds_v3"
  description = "Розмір віртуальних машин у наборі"
}

# Налаштування для автомасштабування (Завдання 4)
variable "autoscale_minimum" {
  type        = number
  default     = 2
  description = "Мінімальна кількість інстансів"
}

variable "autoscale_maximum" {
  type        = number
  default     = 10
  description = "Максимальна кількість інстансів"
}

variable "scale_out_cpu_threshold" {
  type        = number
  default     = 70
  description = "Поріг CPU для збільшення інстансів (%)"
}

variable "scale_in_cpu_threshold" {
  type        = number
  default     = 30
  description = "Поріг CPU для зменшення інстансів (%)"
}

# Налаштування мережі
variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.82.0.0/16"]
  description = "Адресний простір віртуальної мережі"
}

variable "vm_subnet_address_prefix" {
  type        = list(string)
  default     = ["10.82.0.0/24"]
  description = "Адресний префікс підмережі для віртуальних машин"
}

variable "vmss_subnet_address_prefix" {
  type        = list(string)
  default     = ["10.82.1.0/24"]
  description = "Адресний префікс підмережі для масштабованого набору"
}