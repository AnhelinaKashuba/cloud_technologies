terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azuread" {}

data "azuread_domains" "default" {
  only_initial = true
}

locals {
  domain_name = data.azuread_domains.default.domains[0].domain_name
}


resource "azuread_user" "lab_user" {
  user_principal_name = "az104-user1@${local.domain_name}"
  display_name        = "az104-user1"
  password            = random_password.user_pass.result
  account_enabled     = true
  force_password_change = true
  
  job_title     = "IT Lab Administrator"
  department    = "IT"
  usage_location = "US"
}


resource "azuread_user" "guest_user" {
  user_principal_name = "az104-guest@${local.domain_name}"
  display_name        = "Guest User"
  mail_nickname       = "az104guest"
  password            = random_password.guest_pass.result
  account_enabled     = true
  
  # Для симуляції гостя - ставимо іншу посаду
  job_title     = "External IT Admin"
  department    = "External IT"
  usage_location = "US"
}


resource "azuread_group" "lab_group" {
  display_name     = "IT Lab Administrators"
  description      = "Administrators that manage the IT lab"
  security_enabled = true
}


resource "azuread_group_member" "user_member" {
  group_object_id  = azuread_group.lab_group.object_id
  member_object_id = azuread_user.lab_user.object_id
}

resource "azuread_group_member" "guest_member" {
  group_object_id  = azuread_group.lab_group.object_id
  member_object_id = azuread_user.guest_user.object_id
}


resource "random_password" "user_pass" {
  length  = 12
  special = true
}

resource "random_password" "guest_pass" {
  length  = 12
  special = true
}


output "user_credentials" {
  value = {
    username = azuread_user.lab_user.user_principal_name
    password = random_password.user_pass.result
    job_title = azuread_user.lab_user.job_title
  }
  sensitive = true
}

output "guest_credentials" {
  value = {
    username = azuread_user.guest_user.user_principal_name
    password = random_password.guest_pass.result
    job_title = azuread_user.guest_user.job_title
  }
  sensitive = true
}

output "group_info" {
  value = {
    name = azuread_group.lab_group.display_name
    id   = azuread_group.lab_group.object_id
    description = azuread_group.lab_group.description
  }
}

output "domain_info" {
  value = {
    domain = local.domain_name
  }
}
