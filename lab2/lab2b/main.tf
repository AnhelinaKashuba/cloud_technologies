terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "East US"

  tags = {
    CostCenter = "000"
  }
}

# -------------------------------
# 1. DATA: Require tag definition
# -------------------------------
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag and its value on resources"
}

# -----------------------------------------------------
# 2. Assignment of "Require tag" AT RESOURCE GROUP LEVEL
# -----------------------------------------------------
resource "azurerm_resource_group_policy_assignment" "require_tag_assignment" {
  name                 = "require-costcenter-tag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id

  parameters = jsonencode({
    tagName = {
      value = "CostCenter"
    }
    tagValue = {
      value = "000"
    }
  })
}

# -------------------------------
# 3. DATA: Inherit tag definition
# -------------------------------
data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

# -------------------------------------------------------
# 4. Assignment of "Inherit tag" with SystemAssigned identity
# -------------------------------------------------------
resource "azurerm_resource_group_policy_assignment" "inherit_tag_assignment" {
  name                 = "inherit-costcenter-tag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  location             = azurerm_resource_group.rg2.location

  parameters = jsonencode({
    tagName = {
      value = "CostCenter"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------
# 5. Remediation for inherited tag policy
# ---------------------------------------
resource "azurerm_resource_group_policy_remediation" "inherit_tag_remediation" {
  name                 = "inherit-costcenter-remediation"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_assignment_id = azurerm_resource_group_policy_assignment.inherit_tag_assignment.id
}

# ----------------------
# 6. Resource Group Lock
# ----------------------
resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
}
