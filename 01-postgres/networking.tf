#############################################
# VIRTUAL NETWORK CONFIGURATION
#############################################

# -------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL NETWORK (VNET) TO CONTAIN BOTH APPLICATION AND BASTION SUBNETS
# -------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "project-vnet" {
  name                = var.project_vnet                       # VNet name (passed as variable)
  address_space       = ["10.0.0.0/23"]                        # Total address range for all subnets (512 IPs)
  location            = var.project_location                   # Azure region for VNet
  resource_group_name = azurerm_resource_group.project_rg.name # Target resource group
}

# -------------------------------------------------------------------------------------------------
# DEFINE A SUBNET FOR POSTGRESQL DATABASES
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "postgres-subnet" {
  name                 = var.project_subnet                        # Subnet name (variable input)
  resource_group_name  = azurerm_resource_group.project_rg.name    # Must match the VNet’s RG
  virtual_network_name = azurerm_virtual_network.project-vnet.name # Attach to parent VNet
  address_prefixes     = ["10.0.0.0/25"]                           # Lower half of VNet CIDR (128 IPs)

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}


#############################################
# NETWORK SECURITY GROUP (NSG) FOR APP SUBNET
#############################################

resource "azurerm_network_security_group" "postgres-nsg" {
  name                = "postgres-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  # -------- Allow SSH access --------
  security_rule {
    name                       = "Allow-Posgres"
    priority                   = 1000 # Lower = higher priority
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# -------------------------------------------------------------------------------------------------
# BIND POSTGRES SUBNET TO ITS SECURITY GROUP
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "postgres-nsg-assoc" {
  subnet_id                 = azurerm_subnet.postgres-subnet.id
  network_security_group_id = azurerm_network_security_group.postgres-nsg.id
}

