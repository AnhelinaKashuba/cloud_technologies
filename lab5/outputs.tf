output "core_vm_private_ip" {
  description = "Private IP of CoreServicesVM"
  value       = azurerm_network_interface.core_nic.ip_configuration[0].private_ip_address
}

output "manu_vm_private_ip" {
  description = "Private IP of ManufacturingVM"
  value       = azurerm_network_interface.manu_nic.ip_configuration[0].private_ip_address
}
