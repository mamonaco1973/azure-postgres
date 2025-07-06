resource "random_id" "rand" {
  byte_length = 4 # 8-character hex string for storage account name
}

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

resource "azurerm_storage_account" "pgadmin_storage" {
  name                     = "pgadmin${random_id.rand.hex}"
  resource_group_name      = azurerm_resource_group.project_rg.name
  location                 = azurerm_resource_group.project_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "pgadmin_share" {
  name               = "pgadmindata"
  storage_account_id = azurerm_storage_account.pgadmin_storage.id
  quota              = 5
  access_tier        = "TransactionOptimized" # Cheapest tier for Standard storage account
}

resource "azurerm_container_app_environment_storage" "pgadmin_storage" {
  name                         = "pgadmindata"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.pgadmin_storage.name
  share_name                   = azurerm_storage_share.pgadmin_share.name
  access_key                   = azurerm_storage_account.pgadmin_storage.primary_access_key
  access_mode                  = "ReadWrite"

  depends_on = [azurerm_storage_share.pgadmin_share]
}

resource "azurerm_container_app" "pgadmin" {
  name                         = "pgadmin"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.project_rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    volume {
      name         = "pgadmindata"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.pgadmin_storage.name
    }

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

      volume_mounts {
        name = "pgadmindata"
        path = "/var/lib/pgadmin" # Changed from mount_path to path
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

  depends_on = [azurerm_container_app_environment_storage.pgadmin_storage]
}