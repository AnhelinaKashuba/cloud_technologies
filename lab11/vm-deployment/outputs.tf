output "vm_id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}

output "log_analytics_workspace_key" {
  value     = azurerm_log_analytics_workspace.law.primary_shared_key
  sensitive = true
}