# Створення групи ресурсів
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "lab-06"
    created-by  = "terraform"
  }
}

# Створення віртуальної мережі
resource "azurerm_virtual_network" "main" {
  name                = "az104-06-vnet1"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Створення підмереж
resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.prefix]
}

# Створення групи безпеки мережі (NSG) для веб-серверів
resource "azurerm_network_security_group" "web_nsg" {
  name                = "az104-06-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-rdp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ------------------------------------------------------------
# ЗАВДАННЯ 1: Створення трьох віртуальних машин
# ------------------------------------------------------------

# Створення мережевих інтерфейсів
resource "azurerm_network_interface" "vm_nic" {
  count = length(var.vm_names)

  name                = "az104-06-nic${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main["subnet${count.index}"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Прив'язка NSG до мережевих інтерфейсів
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count = length(var.vm_names)

  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# Створення файлів cloud-init для веб-серверів
data "template_file" "cloud_init" {
  count = length(var.vm_names)

  template = file("${path.module}/templates/cloud-init-vm${count.index}.yml")
}

# Створення трьох віртуальних машин Windows
resource "azurerm_windows_virtual_machine" "main" {
  count = length(var.vm_names)

  name                = var.vm_names[count.index]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  zone                = "3" 
  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

  # Налаштування користувацьких даних (cloud-init для Windows)
  custom_data = base64encode(data.template_file.cloud_init[count.index].rendered)
}

# ------------------------------------------------------------
# ЗАВДАННЯ 2: Створення та налаштування Azure Load Balancer
# ------------------------------------------------------------

# Публічна IP-адреса для Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer Standard
resource "azurerm_lb" "main" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.lb_frontend_ip_name
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# Бекенд пул для Load Balancer (vm0 та vm1)
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "az104-be"
}

# Приєднання мережевих інтерфейсів до бекенд пулу
resource "azurerm_network_interface_backend_address_pool_association" "lb_backend" {
  count = 2 # Тільки для vm0 та vm1

  network_interface_id    = azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# Health probe для Load Balancer
resource "azurerm_lb_probe" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "az104-hp"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
}

# Правило балансування навантаження
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "az104-lbrule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.lb_frontend_ip_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

# ------------------------------------------------------------
# ЗАВДАННЯ 3: Створення та налаштування Azure Application Gateway
# ------------------------------------------------------------

# Публічна IP-адреса для Application Gateway
# ------------------------------------------------------------
# ЗАВДАННЯ 3: Створення та налаштування Azure Application Gateway
# ------------------------------------------------------------

# Публічна IP-адреса для Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "az104-gwpip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway (ОНОВЛЕНА КОНФІГУРАЦІЯ)
resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ssl_policy {
    policy_name = "AppGwSslPolicy20220101"  # Актуальна політика для TLS 1.2+
    policy_type = "Predefined"
  }

  sku {
    name     = var.app_gateway_sku
    tier     = var.app_gateway_sku
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.main["subnet-appgw"].id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "az104-appgwbe"
    ip_addresses = [
      azurerm_network_interface.vm_nic[1].private_ip_address,
      azurerm_network_interface.vm_nic[2].private_ip_address
    ]
  }

  backend_address_pool {
    name = "az104-imagebe"
    ip_addresses = [
      azurerm_network_interface.vm_nic[1].private_ip_address
    ]
  }

  backend_address_pool {
    name = "az104-videobe"
    ip_addresses = [
      azurerm_network_interface.vm_nic[2].private_ip_address
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
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # ОДИН PathBasedRouting rule зі всіма шляхами
  request_routing_rule {
    name                       = "az104-gwrule"
    priority                   = 100  # Обов'язковий параметр
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "az104-listener" # Посилання на одного слухача
    url_path_map_name          = "az104-main-path-map" # Посилання на одну карту шляхів
  }

  # ОДНА карта шляхів (url_path_map) для всіх варіантів
  url_path_map {
    name = "az104-main-path-map"
    # Шлях за замовчуванням (наприклад, для "/")
    default_backend_address_pool_name  = "az104-appgwbe"
    default_backend_http_settings_name = "az104-http"

    # Правило для шляху /image/*
    path_rule {
      name = "images-path-rule"
      paths = ["/image/*"]
      backend_address_pool_name  = "az104-imagebe"
      backend_http_settings_name = "az104-http"
    }

    # Правило для шляху /video/*
    path_rule {
      name = "videos-path-rule"
      paths = ["/video/*"]
      backend_address_pool_name  = "az104-videobe"
      backend_http_settings_name = "az104-http"
    }
  }

  depends_on = [
    azurerm_windows_virtual_machine.main
  ]
}