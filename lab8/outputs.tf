output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Назва створеної групи ресурсів"
}

output "virtual_machines" {
  value = {
    for vm in azurerm_windows_virtual_machine.main:
    vm.name => {
      id        = vm.id
      zone      = vm.zone
      private_ip = vm.private_ip_address
    }
  }
  description = "Інформація про створені віртуальні машини"
}

output "data_disk_info" {
  value = {
    name        = azurerm_managed_disk.data_disk.name
    size_gb     = azurerm_managed_disk.data_disk.disk_size_gb
    storage_type = azurerm_managed_disk.data_disk.storage_account_type
    attached_to = azurerm_windows_virtual_machine.main[0].name
  }
  description = "Інформація про диск даних"
}

output "vmss_load_balancer_ip" {
  value       = azurerm_public_ip.vmss_lb_pip.ip_address
  description = "Публічна IP-адреса балансувальника навантаження для VMSS"
}

output "vmss_autoscale_setting" {
  value = {
    name     = azurerm_monitor_autoscale_setting.vmss_autoscale.name
    min_instances = var.autoscale_minimum
    max_instances = var.autoscale_maximum
  }
  description = "Налаштування автомасштабування для VMSS"
}