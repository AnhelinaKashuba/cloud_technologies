resource "azurerm_role_definition" "custom_support" {
  name        = "custom-support-role"
  scope       = "/providers/Microsoft.Management/managementGroups/az104-mg1"

  permissions {
    actions     = ["Microsoft.Support/*"]
    not_actions = ["Microsoft.Support/register/action"]
  }

  assignable_scopes = [
    "/providers/Microsoft.Management/managementGroups/az104-mg1"
  ]
}

resource "azurerm_role_assignment" "custom_support_assign" {
  principal_id         = "46a0c43b-07e5-4f77-adda-002a873c2a55"
  role_definition_id   = azurerm_role_definition.custom_support.role_definition_resource_id
  scope                = "/providers/Microsoft.Management/managementGroups/az104-mg1"
}
