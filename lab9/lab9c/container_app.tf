# Отримуємо дані про існуючу групу ресурсів
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# 1. Створюємо логічну групу середовищ Container Apps (Container Apps Environment)
resource "azurerm_container_app_environment" "main" {
  name                       = var.environment_name
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
}

# 2. Створюємо безпосередньо сам Container App
resource "azurerm_container_app" "main" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = "Single" # Для лаби - одна ревізія

  # Шаблон, що описує контейнери
  template {
    # Визначаємо один контейнер у pod
    container {
      name   = "hello-world-container"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  # Конфігурація вхідного трафіку (Ingress)
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Вивід URL додатку для тестування (Task 2)
output "application_url" {
  value       = azurerm_container_app.main.ingress[0].fqdn
  description = "Публічний URL для доступу до Container App"
}