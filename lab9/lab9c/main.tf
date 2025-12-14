terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Для Container Apps потрібна версія ~> 3.80.0
      version = "~> 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
}