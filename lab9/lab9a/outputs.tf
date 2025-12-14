output "production_url" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "staging_url" {
  value = azurerm_linux_web_app_slot.staging.default_hostname
}

output "production_default_domain" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "staging_default_domain" {
  value = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}