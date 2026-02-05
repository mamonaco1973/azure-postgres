# =================================================================================
# CREATE VIRTUAL NETWORK
# =================================================================================
# Purpose:
#   - Provide a private network boundary for all project subnets.
#
# Notes:
#   - The VNet CIDR is intentionally small (/23) for lab/demo footprints.
#   - Subnets below carve the /23 into two /25 ranges.
# =================================================================================
resource "azurerm_virtual_network" "project_vnet" {
  name                = var.project_vnet
  address_space       = ["10.0.0.0/23"]
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================
# CREATE SUBNET FOR POSTGRESQL FLEXIBLE SERVER
# =================================================================================
# Purpose:
#   - Host Azure Database for PostgreSQL Flexible Server with delegated subnet.
#
# Notes:
#   - PostgreSQL Flexible Server requires subnet delegation to the service.
#   - The /25 provides 128 IPs for service consumption and future growth.
# =================================================================================
resource "azurerm_subnet" "postgres_subnet" {
  name                 = var.project_subnet
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project_vnet.name
  address_prefixes     = ["10.0.0.0/25"]

  delegation {
    name = "postgres-flexible-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# =================================================================================
# CREATE NSG FOR POSTGRESQL SUBNET
# =================================================================================
# Purpose:
#   - Control traffic at the subnet boundary for PostgreSQL workloads.
#
# Notes:
#   - This rule allows inbound TCP/5432. Tighten source ranges for production.
# =================================================================================
resource "azurerm_network_security_group" "postgres_nsg" {
  name                = "postgres-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "Allow-Postgres"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =================================================================================
# ASSOCIATE POSTGRESQL SUBNET WITH NSG
# =================================================================================
# Purpose:
#   - Enforce PostgreSQL subnet security rules by attaching the NSG.
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "postgres_nsg_assoc" {
  subnet_id                 = azurerm_subnet.postgres_subnet.id
  network_security_group_id = azurerm_network_security_group.postgres_nsg.id
}

# =================================================================================
# CREATE SUBNET FOR VMS / APPLICATION WORKLOADS
# =================================================================================
# Purpose:
#   - Host utility/application VMs (e.g., pgweb, jumpbox, test clients).
#
# Notes:
#   - This /25 is the second half of the /23 VNet range.
# =================================================================================
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project_vnet.name
  address_prefixes     = ["10.0.1.0/25"]
}

# =================================================================================
# CREATE NSG FOR VM SUBNET
# =================================================================================
# Purpose:
#   - Allow basic admin and web access to VM-based tooling.
#
# Notes:
#   - HTTP (80) is typically used for web clients (pgweb/admin tools).
#   - SSH (22) is for administration; restrict source ranges for production.
# =================================================================================
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =================================================================================
# ASSOCIATE VM SUBNET WITH NSG
# =================================================================================
# Purpose:
#   - Enforce VM subnet security rules by attaching the NSG.
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
