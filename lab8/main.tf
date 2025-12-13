# Створення групи ресурсів
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "lab-08"
    created-by  = "terraform"
  }
}

# Створення віртуальної мережі та підмереж
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.vm_subnet_address_prefix
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.vmss_subnet_address_prefix
}

# ------------------------------------------------------------
# ЗАВДАННЯ 1: Створення двох віртуальних машин в різних зонах
# ------------------------------------------------------------

# Створення мережевих інтерфейсів для кожної віртуальної машини
resource "azurerm_network_interface" "vm_nic" {
  count = length(var.vm_names)

  name                = "${var.vm_names[count.index]}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    # Не створюємо публічний IP (за вимогою завдання)
  }
}

# Створення двох віртуальних машин Windows Server 2019
resource "azurerm_windows_virtual_machine" "main" {
  count = length(var.vm_names)

  name                = var.vm_names[count.index]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  zone                = var.vm_zones[count.index]
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

  # Вимкнення моніторингу (за вимогою завдання)
  boot_diagnostics {}

  tags = {
    vm-zone = var.vm_zones[count.index]
  }
}

# ------------------------------------------------------------
# ЗАВДАННЯ 2: Керування дисками та масштабування
# ------------------------------------------------------------

# Створення диску даних (Standard HDD, 32 ГБ)
resource "azurerm_managed_disk" "data_disk" {
  name                 = var.data_disk_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_type = "Standard_LRS"  
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = "3"

  tags = {
    description = "Data disk for az104-vm1"
  }
}

# Приєднання диску до першої віртуальної машини
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  virtual_machine_id = azurerm_windows_virtual_machine.main[0].id
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  lun                = 10
  caching            = "ReadWrite"
}

# ------------------------------------------------------------
# ЗАВДАННЯ 3: Створення масштабованого набору віртуальних машин
# ------------------------------------------------------------

# Створення групи безпеки мережі для VMSS
resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "${var.vmss_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Прив'язка NSG до підмережі VMSS
resource "azurerm_subnet_network_security_group_association" "vmss_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vmss_subnet.id
  network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}

# Створення публічної IP-адреси для балансувальника навантаження
resource "azurerm_public_ip" "vmss_lb_pip" {
  name                = "${var.vmss_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Створення балансувальника навантаження
resource "azurerm_lb" "vmss_lb" {
  name                = "${var.vmss_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vmss_lb_pip.id
  }
}

# Створення бекенд-пулу балансувальника
resource "azurerm_lb_backend_address_pool" "vmss_backend_pool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "${var.vmss_name}-backend-pool"
}

# Пробу для балансувальника
resource "azurerm_lb_probe" "vmss_probe" {
  loadbalancer_id     = azurerm_lb.vmss_lb.id
  name                = "${var.vmss_name}-probe"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
}

# Правило балансувальника
resource "azurerm_lb_rule" "vmss_rule" {
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "${var.vmss_name}-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
}

# Створення масштабованого набору віртуальних машин
resource "azurerm_windows_virtual_machine_scale_set" "main" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.vmss_sku
  instances           = var.vmss_instance_count
  zones               = var.vmss_zones
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.vmss_name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss_subnet.id
      
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.vmss_backend_pool.id
      ]
    }
  }

  # Вимкнення моніторингу (за вимогою завдання)
  boot_diagnostics {}

  depends_on = [
    azurerm_subnet_network_security_group_association.vmss_nsg_assoc
  ]
}

# ------------------------------------------------------------
# ЗАВДАННЯ 4: Налаштування автомасштабування для VMSS
# ------------------------------------------------------------

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.autoscale_minimum
      minimum = var.autoscale_minimum
      maximum = var.autoscale_maximum
    }

    # Правило для збільшення інстансів (Scale-Out)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Правило для зменшення інстансів (Scale-In)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.main
  ]
}