terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.6"
    }
  }
}

provider "azurerm" {
  features {

  }
}

resource "azurerm_resource_group" "azure_static_site_resource_group" {
  name     = "azure_static_site_resource_group"
  location = "uksouth"
}

resource "azurerm_container_registry" "azure_static_site_containers" {
  name                = "deploymentpracticeacrartie"
  resource_group_name = azurerm_resource_group.azure_static_site_resource_group.name
  location            = "uksouth"
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "environment" {
  name                = "deploymentpracticeace"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.azure_static_site_resource_group.name
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "container_App" {
  name                         = "azurerm-container-app"
  resource_group_name          = azurerm_resource_group.azure_static_site_resource_group.name
  workload_profile_name        = "Consumption"
  revision_mode                = "Single"
  container_app_environment_id = azurerm_container_app_environment.environment.id

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.azure_static_site_containers.admin_password
  }

  registry {
    server               = azurerm_container_registry.azure_static_site_containers.login_server
    username             = azurerm_container_registry.azure_static_site_containers.admin_username
    password_secret_name = "acr-password"
  }
  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "my-container"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}