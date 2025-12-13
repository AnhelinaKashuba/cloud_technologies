terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
    
  required_version = ">= 1.4.0"
}

provider "azurerm" {
  features {}
  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
  tenant_id       = "97f609c3-a070-400b-9485-c77f956a1b7f"  
}


provider "azuread" {}