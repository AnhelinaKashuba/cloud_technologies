
# Створення Action Group для сповіщень
resource "azurerm_monitor_action_group" "action_group" {
  name                = "AlertOpsTeam"
  resource_group_name = var.resource_group_name
  short_name          = "AlertOps"

  email_receiver {
    name                    = "VM was deleted"
    email_address           = var.email_address
    use_common_alert_schema = true
  }

  tags = {
    environment = "lab11"
  }
}

# Створення Alert Rule для видалення VM
resource "azurerm_monitor_activity_log_alert" "vm_delete_alert" {
  name                = "VM was deleted"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [var.vm_id]

  criteria {
    operation_name = "Microsoft.Compute/virtualMachines/delete"
    category       = "Administrative"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }

  description = "A VM in your resource group was deleted"
}

# Створення Alert Processing Rule для планового обслуговування
resource "azurerm_monitor_alert_processing_rule_suppression" "maintenance_rule" {
  name                = "planned-maintenance" 
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]

  condition {
    alert_context {
      operator = "Contains"
      values   = ["virtualMachines"]
    }
  }

  schedule {
    effective_from  = "${substr(timestamp(), 0, 10)}T22:00:00"
    effective_until = "${substr(timeadd(timestamp(), "24h"), 0, 10)}T07:00:00"
    time_zone       = "UTC"
  }

  description = "Suppress notifications during planned maintenance"
}

# Додаткова метрика для CPU
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "High CPU Usage"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }

  window_size = "PT5M"
  frequency   = "PT1M"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-vm-monitor"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "vm-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "lawdest"
    }
  }

  data_sources {
    performance_counter {
      name = "perf"
      streams = ["Microsoft-Perf"]
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\LogicalDisk(_Total)\\Free Megabytes"
      ]
      sampling_frequency_in_seconds = 60
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["lawdest"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "vm_assoc" {
  name                    = "vm-dcr-association" 
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}
