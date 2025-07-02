#############################################
# AZURE PROVIDER CONFIGURATION
#############################################

# Configure the AzureRM provider (required for interacting with Azure)
provider "azurerm" {
  features {}                     # Enables all optional AzureRM features (default empty block required)
                                  # Do NOT remove this, even if it looks empty
}

#############################################
# DATA SOURCES FOR AZURE CONTEXT
#############################################

# Fetch metadata about the current subscription
data "azurerm_subscription" "primary" {}  
# Provides details like subscription ID, tenant ID, and display name
# Useful for tagging, auditing, or linking resources to subscription context

# Get authentication details for the current Azure CLI / Service Principal session
data "azurerm_client_config" "current" {}
# Exposes object_id, client_id, and tenant_id
# Essential for role assignments, policy bindings, and managed identity linkage

#############################################
# RESOURCE GROUP DEFINITION
#############################################

# Create the primary resource group that will contain all infrastructure
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group       # Logical container for Azure resources
                                              # Name must be globally unique within the subscription
  location = var.project_location             # Region where resources will be deployed
                                              # Pick the region closest to your users or workloads
}
