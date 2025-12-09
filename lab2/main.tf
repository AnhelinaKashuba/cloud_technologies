terraform {
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
resource "azurerm_management_group" "mg1" {
  name        = "az104-mg1"
  display_name = "az104-mg1"
}
