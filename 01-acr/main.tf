# Configure the AzureRM provider
provider "azurerm" {
  # Enables the default features of the provider
  features {}
}

# Data source to fetch details of the primary subscription
data "azurerm_subscription" "primary" {}

# Data source to fetch the details of the current Azure client
data "azurerm_client_config" "current" {}

# Define a resource group for all resources in this project
resource "azurerm_resource_group" "project_rg" {
  name     = var.resource_group_name  # Name of the resource group
  location = "Central US"             # Region where resources will be deployed
}