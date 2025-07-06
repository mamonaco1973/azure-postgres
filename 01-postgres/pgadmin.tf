
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_container_group" "pgadmin" {
  name                = "pgadmin"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  os_type             = "Linux"

  ip_address_type = "Public"
  dns_name_label  = "pgadmin-${random_string.suffix.result}"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4:latest"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      PGADMIN_DEFAULT_EMAIL    = "admin@localhost.com"
      PGADMIN_DEFAULT_PASSWORD = random_password.pgadmin_password.result
    }
  }
}