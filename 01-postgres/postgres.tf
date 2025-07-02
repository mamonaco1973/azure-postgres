# -------------------------------------------------
# PostgreSQL Flexible Server
# -------------------------------------------------
resource "azurerm_postgresql_flexible_server" "public" {
  name                   = "public-postgres-instance"
  resource_group_name    = azurerm_resource_group.project_rg.name
  location               = azurerm_resource_group.project_rg.location
  version                = "15"
  administrator_login    = "postgres"
  administrator_password = random_password.postgres_password.result
  private_dns_zone_id    = null
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_my_ip" {
  name                = "AllowAllIPs"
  server_id           = azurerm_postgresql_flexible_server.public.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
