resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.project_resource_group}-logs"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.project_resource_group}-env"
  location                   = azurerm_resource_group.project_rg.location
  resource_group_name        = azurerm_resource_group.project_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
}

resource "azurerm_container_app" "pgadmin" {
  name                         = "pgadmin"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.project_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "pgadmin"
      image  = "dpage/pgadmin4:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PGADMIN_DEFAULT_EMAIL"
        value = "admin@local"
      }

      env {
        name  = "PGADMIN_DEFAULT_PASSWORD"
        value = "Password1!"
      }
    }
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

}
