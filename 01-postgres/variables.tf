# =================================================================================
# PROJECT RESOURCE GROUP NAME
# =================================================================================
# Purpose:
#   - Define the name of the Azure Resource Group.
#   - Acts as the top-level container for all deployed resources.
#
# Notes:
#   - Override via tfvars or CLI to reuse this configuration across environments.
# =================================================================================
variable "project_resource_group" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "postgres-rg"
}

# =================================================================================
# PROJECT VIRTUAL NETWORK NAME
# =================================================================================
# Purpose:
#   - Define the name of the Azure Virtual Network (VNet).
#   - Provides the private network boundary for the project.
#
# Notes:
#   - Changing this value does not affect CIDR ranges defined elsewhere.
# =================================================================================
variable "project_vnet" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "postgres-vnet"
}

# =================================================================================
# PROJECT SUBNET NAME
# =================================================================================
# Purpose:
#   - Define the name of the primary subnet inside the VNet.
#   - Used for PostgreSQL Flexible Server delegation and VM workloads.
#
# Notes:
#   - Keep database and utility workloads in separate subnets if expanding.
# =================================================================================
variable "project_subnet" {
  description = "Name of the Azure Subnet within the Virtual Network"
  type        = string
  default     = "postgres-subnet"
}

# =================================================================================
# PROJECT DEPLOYMENT REGION
# =================================================================================
# Purpose:
#   - Define the Azure region where all resources are deployed.
#
# Notes:
#   - The region must support PostgreSQL Flexible Server.
#   - Use consistent regions across all resources to avoid cross-region issues.
# =================================================================================
variable "project_location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "Central US"
}
