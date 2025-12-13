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
  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg7"
  location = "East US"
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "GRS"

  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# Lifecycle rule (Move to Cool after 30 days)
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.sa.id

  rule {
    name    = "movetocool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

# Blob Container
resource "azurerm_storage_container" "data" {
  name                 = "data"
  storage_account_id   = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Immutable Blob Policy (180 days)
resource "azurerm_storage_container_immutability_policy" "immutability" {
  storage_container_resource_manager_id  = azurerm_storage_container.data.resource_manager_id
  immutability_period_in_days            = 180
  protected_append_writes_all_enabled    = true
}

# File Share
resource "azurerm_storage_share" "share" {
  name                 = "share1"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50
  access_tier          = "TransactionOptimized"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

# resource "azurerm_storage_account_network_rules" "rules" {
#   storage_account_id = azurerm_storage_account.sa.id
#
#   default_action             = "Deny"
#   virtual_network_subnet_ids = [azurerm_subnet.default.id]
# }

