output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "blob_container_name" {
  value = azurerm_storage_container.data.name
}

output "file_share_name" {
  value = azurerm_storage_share.share.name
}
