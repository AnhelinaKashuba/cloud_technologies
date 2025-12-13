output "load_balancer_public_ip" {
  description = "public IP address of load B=balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}
output "app_gateway_public_ip" {
  description = "public IP address of Application Gateway"
  value       = azurerm_public_ip.gwpip.ip_address
}