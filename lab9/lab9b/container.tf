# Використовуємо існуючу групу ресурсів з попередньої лаби
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Створення екземпляра контейнера Azure (Task 1)
resource "azurerm_container_group" "aci" {
  name                = var.container_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = var.dns_name_label # Публічна адреса
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  # Визначення контейнера
  container {
    name   = "hello-world-container"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    # Відкриваємо порт 80 для веб-доступу
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = "lab"
  }
}

# Вивід для зручного тестування (Task 2)
output "container_fqdn" {
  value = azurerm_container_group.aci.fqdn
  description = "Повне доменне ім'я (FQDN) для доступу до контейнера"
}

output "container_ip_address" {
  value = azurerm_container_group.aci.ip_address
  description = "Публічна IP-адреса контейнера"
}