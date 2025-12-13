output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Назва створеної групи ресурсів"
}

output "load_balancer_ip" {
  value       = azurerm_public_ip.lb_pip.ip_address
  description = "Публічна IP-адреса Load Balancer для тестування"
}

output "application_gateway_ip" {
  value       = azurerm_public_ip.appgw_pip.ip_address
  description = "Публічна IP-адреса Application Gateway для тестування"
}

output "virtual_machines" {
  value = {
    for vm in azurerm_windows_virtual_machine.main:
    vm.name => {
      private_ip = azurerm_network_interface.vm_nic[index(var.vm_names, vm.name)].private_ip_address
      subnet     = split("/", azurerm_subnet.main["subnet${index(var.vm_names, vm.name)}"].address_prefixes[0])[0]
    }
  }
  description = "Інформація про створені віртуальні машини"
}