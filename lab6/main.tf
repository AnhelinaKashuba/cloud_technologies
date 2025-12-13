# main.tf
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg6-lab-final"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet1-lab-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.60.0.0/22"]
}

# Тільки 2 підмережі (для кожної ВМ)
resource "azurerm_subnet" "subnet" {
  count                = 2
  name                 = "subnet${count.index}" 
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.vnet.address_space[0], 2, count.index)]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "az104-06-nsg1-lab-final"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Тільки 2 мережеві картки
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "az104-06-nic${count.index}-lab" 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
} 

# 2 ВМ, розмір D2s_v4 (x64)
resource "azurerm_windows_virtual_machine" "vm" {
  count                 = 2
  name                  = "az104-06-vm${count.index}-lab" 
  computer_name         = "vm${count.index}-lab" 
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_D2s_v4"
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" 
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }
}

# Кастомний скрипт для встановлення IIS
locals {
  iis_base_script = "Install-WindowsFeature -name Web-Server -IncludeManagementTools; Start-Sleep -Seconds 30; remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' -ErrorAction SilentlyContinue; Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
}

# Розширення тільки для 2 ВМ
resource "azurerm_virtual_machine_extension" "cse" {
  count                = 2
  name                 = "customScriptExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -Command \"${local.iis_base_script}\""
  })
}

# Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip-lab-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"   
}

resource "azurerm_lb" "lb" {
  name                = "az104-lb-lab-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard" 

  frontend_ip_configuration {
    name                 = "az104-fe"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "be_pool" {
  name            = "az104-be"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "hp" {
  name                = "az104-hp"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "az104-lbrule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "az104-fe"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.be_pool.id]
  probe_id                       = azurerm_lb_probe.hp.id
  idle_timeout_in_minutes        = 4
  enable_tcp_reset               = true
}

# Прив'язка тільки двох мережевих карток до LB
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig1" 
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

# Application Gateway
resource "azurerm_subnet" "appgw" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.3.224/27"]
}

resource "azurerm_public_ip" "gwpip" {
  name                = "az104-gwpip-lab-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "az104-appgw-lab-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
  
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 3
  }
  
  enable_http2 = false

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "appgw-fe-public"
    public_ip_address_id = azurerm_public_ip.gwpip.id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  # Бекенд-пул: обидві наші ВМ
  backend_address_pool {
    name = "az104-appgwbe"
    ip_addresses = [
      azurerm_network_interface.nic[0].private_ip_address,
      azurerm_network_interface.nic[1].private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "az104-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }



  http_listener {
    name                           = "az104-listener"
    frontend_ip_configuration_name = "appgw-fe-public"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  # Просте правило: весь трафік на один пул
  request_routing_rule {
    name                       = "az104-gwrule"
    rule_type                  = "Basic"
    priority                   = 10
    http_listener_name         = "az104-listener"
    backend_address_pool_name  = "az104-appgwbe"
    backend_http_settings_name = "az104-http"
  }
}