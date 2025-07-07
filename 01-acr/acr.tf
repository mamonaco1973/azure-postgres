# Creates an Azure Container Registry (ACR) for storing Docker container images.
resource "azurerm_container_registry" "flask_acr" {
  # Globally unique ACR name, using a subscription ID prefix to avoid conflicts.
  name = "pgutils${substr(data.azurerm_client_config.current.subscription_id, 0, 6)}"

  # The Resource Group where the ACR is deployed.
  resource_group_name = azurerm_resource_group.project_rg.name

  # The region where the ACR is hosted, matching the Resource Group's location.
  location = azurerm_resource_group.project_rg.location

  # ACR pricing tier options:
  # - "Basic": Cost-effective, limited features.
  # - "Standard": More storage, better performance.
  # - "Premium": Geo-replication, advanced security.
  sku = "Basic"
  admin_enabled       = true   
}