# =================================================================================
# CONFIGURE THE AZURERM PROVIDER
# =================================================================================
# Purpose:
#   - Enable Terraform to manage Azure resources via the AzureRM provider.
#
# Notes:
#   - The `features {}` block is required by the provider, even if empty.
#   - Removing this block will cause provider initialization to fail.
# =================================================================================
provider "azurerm" {
  features {}
}

# =================================================================================
# FETCH CURRENT AZURE SUBSCRIPTION DETAILS
# =================================================================================
# Purpose:
#   - Retrieve metadata about the active Azure subscription.
#
# Exposes:
#   - subscription_id
#   - display_name
#   - tenant_id
#
# Typical Uses:
#   - Resource tagging
#   - Cross-subscription logic
#   - Tenant- or subscription-scoped references
# =================================================================================
data "azurerm_subscription" "primary" {}

# =================================================================================
# FETCH AUTHENTICATION CONTEXT FOR CURRENT PRINCIPAL
# =================================================================================
# Purpose:
#   - Identify the Azure AD principal executing Terraform.
#
# Exposes:
#   - object_id
#   - client_id
#   - tenant_id
#
# Typical Uses:
#   - Role assignments
#   - Managed identity bindings
#   - Secure access control configuration
# =================================================================================
data "azurerm_client_config" "current" {}

# =================================================================================
# CREATE PRIMARY RESOURCE GROUP
# =================================================================================
# Purpose:
#   - Define a single logical container for all project resources.
#
# Notes:
#   - Acts as the root scope for lifecycle management and cleanup.
#   - Region and name are provided via input variables.
# =================================================================================
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group
  location = var.project_location
}
