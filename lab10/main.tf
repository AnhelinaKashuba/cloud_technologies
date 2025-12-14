# Конфігурація провайдера
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80"
    }
  }
}

provider "azurerm" {
  features {
    recovery_service {
      vm_backup_stop_protection_and_retain_data_on_destroy = true
      purge_protected_items_from_vault_on_destroy          = true
    }
  }
}

# Генерація унікальних імен
resource "random_pet" "rg_region1_name" {
  prefix = "az104-rg"
}

resource "random_pet" "rg_region2_name" {
  prefix = "az104-rg"
}

resource "random_string" "unique" {
  length  = 12
  lower   = true
  upper   = false
  numeric = false
  special = false
}

# === ЗАВДАННЯ 1: ІНФРАСТРУКТУРА ===
resource "azurerm_resource_group" "region1" {
  name     = "${random_pet.rg_region1_name.id}-westeurope"
  location = "West Europe"  # ← ВИПРАВЛЕНО: з West US на West Europe
}

# Віртуальна мережа та підмережа
resource "azurerm_virtual_network" "vnet_region1" {
  name                = "${random_string.unique.id}-vnet-westeurope"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
}

resource "azurerm_subnet" "subnet_region1" {
  name                 = "${random_string.unique.id}-subnet-westeurope"
  resource_group_name  = azurerm_resource_group.region1.name
  virtual_network_name = azurerm_virtual_network.vnet_region1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Мережева група безпеки
resource "azurerm_network_security_group" "nsg_region1" {
  name                = "${random_string.unique.id}-nsg-westeurope"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Публічна IP-адреса та мережевий інтерфейс
resource "azurerm_public_ip" "pip_region1" {
  name                = "pip-westeurope-01"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic_region1" {
  name                = "${random_string.unique.id}-nic-westeurope"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_region1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_region1.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_region1" {
  network_interface_id      = azurerm_network_interface.nic_region1.id
  network_security_group_id = azurerm_network_security_group.nsg_region1.id
}

# Обліковий запис зберігання для діагностики
resource "random_id" "storage_id" {
  byte_length = 8
}

resource "azurerm_storage_account" "boot_diag_region1" {
  name                     = "diagbootwesteu01"
  resource_group_name      = azurerm_resource_group.region1.name
  location                 = azurerm_resource_group.region1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Віртуальна машина Windows
resource "random_password" "vm_password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "azurerm_windows_virtual_machine" "az104_10_vm0" {
  name                = "${random_string.unique.id}-vm-westeurope"
  computer_name       = "az104vm01"
  resource_group_name = azurerm_resource_group.region1.name
  location            = azurerm_resource_group.region1.location
  size                = "Standard_D2s_v3"  # ← ВИПРАВЛЕНО: замінив на доступний розмір

  admin_username = "localadmin"
  admin_password = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.nic_region1.id
  ]

  os_disk {
    name                 = "${random_string.unique.id}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diag_region1.primary_blob_endpoint
  }
}

# === ЗАВДАННЯ 2: СХОВИЩЕ СЛУЖБ ВІДНОВЛЕННЯ ===
resource "azurerm_recovery_services_vault" "rsv_region1" {
  name                = "${random_string.unique.id}-rsv-westeurope"
  resource_group_name = azurerm_resource_group.region1.name
  location            = azurerm_resource_group.region1.location
  sku                 = "Standard"
  soft_delete_enabled = true
}

# === ЗАВДАННЯ 3: РЕЗЕРВНЕ КОПІЮВАННЯ ВМ ===
resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = "${random_string.unique.id}-policy-daily"
  resource_group_name = azurerm_resource_group.region1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_region1.name

  backup {
    frequency = "Daily"
    time      = "00:00"
  }

  retention_daily {
    count = 7
  }
  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }
}

resource "azurerm_backup_protected_vm" "vm_backup" {
  resource_group_name = azurerm_resource_group.region1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_region1.name
  source_vm_id        = azurerm_windows_virtual_machine.az104_10_vm0.id
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
}

# === ЗАВДАННЯ 4: МОНІТОРИНГ ===
resource "azurerm_storage_account" "monitoring_storage" {
  name                     = "monstorewesteu01"
  resource_group_name      = azurerm_resource_group.region1.name
  location                 = azurerm_resource_group.region1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "vault_diag" {
  depends_on = [azurerm_storage_account.monitoring_storage]
  name                       = "${random_string.unique.id}-vault-diag"
  target_resource_id         = azurerm_recovery_services_vault.rsv_region1.id
  storage_account_id         = azurerm_storage_account.monitoring_storage.id

  enabled_log {
    category = "AzureBackupReport"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# === ЗАВДАННЯ 5: АВАРІЙНЕ ВІДНОВЛЕННЯ ===
resource "azurerm_resource_group" "region2" {
  name     = "${random_pet.rg_region2_name.id}-eastus"  # ← ВИПРАВЛЕНО: інший регіон для DR
  location = "East US"  # ← ВИПРАВЛЕНО: інший регіон
}

resource "azurerm_recovery_services_vault" "rsv_region2" {
  name                = "${random_string.unique.id}-rsv-eastus"  # ← ОНОВЛЕНО ім'я
  resource_group_name = azurerm_resource_group.region2.name
  location            = azurerm_resource_group.region2.location
  sku                 = "Standard"
  soft_delete_enabled = true
}

# Додаткові ресурси для реплікації
resource "azurerm_storage_account" "cache_storage" {
  name                     = "${random_string.unique.id}cachestor"
  resource_group_name      = azurerm_resource_group.region2.name
  location                 = azurerm_resource_group.region2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}