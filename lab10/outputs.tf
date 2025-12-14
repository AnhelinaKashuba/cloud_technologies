output "resource_group_region1_name" {
  description = "Ім'я групи ресурсів в регіоні 1"
  value       = azurerm_resource_group.region1.name
}

output "vm_name" {
  description = "Ім'я віртуальної машини"
  value       = azurerm_windows_virtual_machine.az104_10_vm0.name
}

output "recovery_vault_region1_name" {
  description = "Ім'я сховища служб відновлення в регіоні 1"
  value       = azurerm_recovery_services_vault.rsv_region1.name
}

output "recovery_vault_region2_name" {
  description = "Ім'я сховища служб відновлення в регіоні 2"
  value       = azurerm_recovery_services_vault.rsv_region2.name
}

output "monitoring_storage_account_name" {
  description = "Ім'я облікового запису зберігання для моніторингу"
  value       = azurerm_storage_account.monitoring_storage.name
}