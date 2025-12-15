# Створення віртуальної мережі
resource "azurerm_virtual_network" "vnet" {
  name                = "az104-vnet11"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Створення підмережі
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Створення публічної IP-адреси
resource "azurerm_public_ip" "public_ip" {
  name                = "az104-vm0-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Створення мережевої групи безпеки
resource "azurerm_network_security_group" "nsg" {
  name                = "az104-vm0-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Створення мережевого інтерфейсу
resource "azurerm_network_interface" "nic" {
  name                = "az104-vm0-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Прив'язка NSG до NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Створення віртуальної машини Windows
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "az104-vm0"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "localadmin"
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  # Встановлення агента Azure Monitor
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "lab11"
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "az104-law11"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  timeouts {
    create = "30m"
    read   = "5m"
    update = "30m"
    delete = "30m"
  }
}

resource "azurerm_virtual_machine_extension" "ama_extension" {
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true


  settings = jsonencode({
    "workspaceId" = azurerm_log_analytics_workspace.law.workspace_id
  })

  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.law.primary_shared_key
  })

}

