output "core_vnet_id" {
  value = azurerm_virtual_network.core_vnet.id
}

output "mfg_vnet_id" {
  value = azurerm_virtual_network.mfg_vnet.id
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg_secure.id
}

output "public_dns_zone" {
  value = azurerm_dns_zone.public_zone.name
}

output "private_dns_zone" {
  value = azurerm_private_dns_zone.private_zone.name
}
