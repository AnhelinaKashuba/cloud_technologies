provider "azurerm" {
  features {}
  subscription_id = "92c78445-2f1c-48bc-a6f3-be872057438d"
}

# Створення групи ресурсів
resource "azurerm_resource_group" "rg11" {
  name     = "az104-rg11"
  location = "West Europe"
}


module "monitoring" {
  source = "./monitoring"

  resource_group_name = azurerm_resource_group.rg11.name
  location            = azurerm_resource_group.rg11.location
  vm_id               = module.vm.vm_id
  email_address       = var.email_address
}

module "vm" {
  source = "./vm-deployment"

  resource_group_name = azurerm_resource_group.rg11.name
  location            = azurerm_resource_group.rg11.location
  admin_password      = var.admin_password
}
