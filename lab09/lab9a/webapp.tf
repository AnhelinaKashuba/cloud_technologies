# Створення групи ресурсів (Task 1)
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Створення App Service Plan (Task 1)
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.web_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# Створення основного Web App (Task 1 - Production slot)
resource "azurerm_linux_web_app" "main" {
  name                = var.web_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      php_version = "8.2"
    }
  }
}

# Створення staging deployment slot (Task 2)
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id

  site_config {
    application_stack {
      php_version = "8.2"
    }
  }
}

# Налаштування deployment для staging slot з GitHub (Task 3)
# resource "azurerm_app_service_source_control" "staging_slot" {
#  app_id                 = azurerm_linux_web_app_slot.staging.id
#  repo_url               = "https://github.com/Azure-Samples/php-docs-hello-world"
#  branch                 = "master"
#  use_manual_integration = true
  
  # Чекаємо створення слота перед налаштуванням deployment
#  depends_on = [azurerm_linux_web_app_slot.staging]
#}

# Налаштування autoscaling (Task 5)
resource "azurerm_monitor_autoscale_setting" "webapp_scale" {
  name                = "autoscale-${var.web_app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_service_plan.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}