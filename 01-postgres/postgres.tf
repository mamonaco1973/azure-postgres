# =================================================================================
# CREATE PRIVATE DNS ZONE FOR POSTGRESQL FLEXIBLE SERVER
# =================================================================================
# Purpose:
#   - Provide private name resolution for PostgreSQL Flexible Server endpoints.
#
# Notes:
#   - This DNS zone is required for Private Link–based PostgreSQL deployments.
#   - Resources inside the linked VNet will resolve the server FQDN to a
#     private IP address.
# =================================================================================
resource "azurerm_private_dns_zone" "postgres_private_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================
# LINK PRIVATE DNS ZONE TO PROJECT VNET
# =================================================================================
# Purpose:
#   - Enable private DNS resolution within the VNet.
#
# Notes:
#   - Without this link, VMs and services in the VNet will fail to resolve the
#     PostgreSQL private endpoint hostname.
# =================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "postgres-dns-link"
  resource_group_name   = azurerm_resource_group.project_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_private_dns.name
  virtual_network_id    = azurerm_virtual_network.project_vnet.id
}

# =================================================================================
# CREATE PRIVATE POSTGRESQL FLEXIBLE SERVER
# =================================================================================
# Purpose:
#   - Deploy PostgreSQL Flexible Server with private-only network access.
#   - Integrate the server with a delegated subnet and Private DNS.
#
# Notes:
#   - public_network_access_enabled = false enforces private connectivity.
#   - delegated_subnet_id must reference a subnet delegated to the PostgreSQL
#     Flexible Server service.
#   - private_dns_zone_id ensures internal name resolution via Azure Private DNS.
# =================================================================================
resource "azurerm_postgresql_flexible_server" "postgres_instance" {
  name                = "postgres-instance-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location

  version                = "15"
  administrator_login    = "postgres"
  administrator_password = random_password.postgres_password.result

  storage_mb                   = 32768
  sku_name                     = "B_Standard_B1ms"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  zone                         = "1"

  public_network_access_enabled = false

  delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres_private_dns.id
}
