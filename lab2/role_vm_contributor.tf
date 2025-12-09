data "azurerm_role_definition" "vm_contrib" {
  name = "Virtual Machine Contributor"
  scope = "/providers/Microsoft.Management/managementGroups/az104-mg1"
}

resource "azurerm_role_assignment" "vm_contrib_assign" {
  principal_id   = "46a0c43b-07e5-4f77-adda-002a873c2a55"
  role_definition_id = data.azurerm_role_definition.vm_contrib.role_definition_id
  scope = "/providers/Microsoft.Management/managementGroups/az104-mg1"
}
