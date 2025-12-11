# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ---------------------------
# CoreServicesVnet
# ---------------------------
resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "core_shared" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.10.0/24"]
  # network_security_group_id - assigned later after NSG is created (we'll set it below using depends_on)
}

resource "azurerm_subnet" "core_db" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}

# ---------------------------
# ManufacturingVnet
# ---------------------------
resource "azurerm_virtual_network" "mfg_vnet" {
  name                = "ManufacturingVnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "mfg_sensor1" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "mfg_sensor2" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.21.0/24"]
}

# ---------------------------
# Application Security Group (ASG)
# ---------------------------
resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ---------------------------
# Network Security Group (NSG)
# ---------------------------
resource "azurerm_network_security_group" "nsg_secure" {
  name                = "myNSGSecure"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Inbound rule: allow from ASG to ports 80,443
  security_rule {
    name                       = "AllowASG"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
    destination_address_prefix = "*"
  }

  # Outbound rule: deny Internet
  security_rule {
    name                       = "DenyInternetOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_address_prefix = "Internet"
    source_address_prefix      = "*"
  }

  # Note: Azure creates a built-in AllowInternetOutBound with priority 65001.
  # Our DenyInternetOutbound has priority 4096 so it takes precedence.
}

# Associate NSG with Core SharedServicesSubnet.
# Depending on provider version, you can set network_security_group_id directly on subnet.
resource "azurerm_subnet_network_security_group_association" "assoc_core_shared_nsg" {
  subnet_id                 = azurerm_subnet.core_shared.id
  network_security_group_id = azurerm_network_security_group.nsg_secure.id
  depends_on = [azurerm_network_security_group.nsg_secure]
}

# ---------------------------
# Public DNS zone & A record
# ---------------------------
resource "azurerm_dns_zone" "public_zone" {
  name                = "contoso12345.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}

# ---------------------------
# Private DNS zone, record and VNet link
# ---------------------------
resource "azurerm_private_dns_zone" "private_zone" {
  name                = "private.contoso12345.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "sensorvm" {
  name                = "sensorvm"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "mfg_link" {
  name                  = "manufacturing-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_zone.name
  virtual_network_id    = azurerm_virtual_network.mfg_vnet.id
  depends_on            = [azurerm_virtual_network.mfg_vnet]
  registration_enabled  = false
}
