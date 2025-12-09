terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true

  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
}

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg3"
  location = "East US"
}

resource "azurerm_managed_disk" "disk1" {
  name                 = "az104-disk1"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}


resource "azurerm_managed_disk" "disk2" {
  name                 = "az104-disk2"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}
 
resource "azurerm_managed_disk" "disk3" {
  name                 = "az104-disk3"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_managed_disk" "disk4" {
  name                 = "az104-disk4"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_managed_disk" "disk5" {
  name                 = "az104-disk5"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

