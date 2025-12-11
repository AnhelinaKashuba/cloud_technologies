terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}

  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Network Security Group - block inbound (no public RDP)
resource "azurerm_network_security_group" "deny_inbound" {
  name                = "nsg-deny-inbound"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # no inbound security rules -> effectively blocks RDP from Internet for public IPs (we won't create public IPs)
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# CoreServices VNet
resource "azurerm_virtual_network" "core" {
  name                = "CoreServicesVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "core_subnet_core" {
  name                 = "Core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.0.0.0/24"]
}

# perimeter subnet (for route to virtual appliance)
resource "azurerm_subnet" "core_subnet_perimeter" {
  name                 = "perimeter"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.0.1.0/24"]
 }

# Manufacturing VNet
resource "azurerm_virtual_network" "manufacturing" {
  name                = "ManufacturingVnet"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "manufacturing_subnet" {
  name                 = "Manufacturing"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["172.16.0.0/24"]
}

# NIC + VM helper: CoreServicesVM (no public IP)
resource "azurerm_network_interface" "core_nic" {
  name                = "core-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.core_subnet_core.id
    private_ip_address_allocation = "Dynamic"
    # no public IP
  }
}

resource "azurerm_windows_virtual_machine" "core_vm" {
  name                  = "CoreServicesVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DC1s_v3"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.core_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "core-osdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }
}

# NIC + VM: ManufacturingVM (no public IP)
resource "azurerm_network_interface" "manu_nic" {
  name                = "manu-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.manufacturing_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "manu_vm" {
  name                  = "ManufacturingVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DC1s_v3"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.manu_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "manu-osdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }
}

# Virtual network peerings (two directions)
resource "azurerm_virtual_network_peering" "core_to_manu" {
  name                      = "CoreServicesVnet-to-ManufacturingVnet"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.core.name
  remote_virtual_network_id = azurerm_virtual_network.manufacturing.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # allow_gateway_transit etc. as needed
}

resource "azurerm_virtual_network_peering" "manu_to_core" {
  name                      = "ManufacturingVnet-to-CoreServicesVnet"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.manufacturing.name
  remote_virtual_network_id = azurerm_virtual_network.core.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Route table and a route to a "future NVA" in perimeter (10.0.1.7)
resource "azurerm_route_table" "rt_core" {
  name                = "rt-CoreServices"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "perimeter_to_core" {
  name                   = "PerimetertoCore"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_core.name
  address_prefix         = "10.0.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.7"
}

# Associate route table with Core subnet (Core)
resource "azurerm_subnet_route_table_association" "core_route_assoc" {
  subnet_id      = azurerm_subnet.core_subnet_core.id
  route_table_id = azurerm_route_table.rt_core.id
}


resource "azurerm_subnet_network_security_group_association" "core_core_assoc" {
  subnet_id                 = azurerm_subnet.core_subnet_core.id
  network_security_group_id = azurerm_network_security_group.deny_inbound.id
}

resource "azurerm_subnet_network_security_group_association" "core_perimeter_assoc" {
  subnet_id                 = azurerm_subnet.core_subnet_perimeter.id
  network_security_group_id = azurerm_network_security_group.deny_inbound.id
}

resource "azurerm_subnet_network_security_group_association" "manufacturing_assoc" {
  subnet_id                 = azurerm_subnet.manufacturing_subnet.id
  network_security_group_id = azurerm_network_security_group.deny_inbound.id
}

