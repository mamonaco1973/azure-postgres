#############################################
# VIRTUAL NETWORK CONFIGURATION
#############################################

# -------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL NETWORK (VNET) TO CONTAIN BOTH APPLICATION AND BASTION SUBNETS
# -------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "project-vnet" {
  name                = var.project_vnet                               # VNet name (passed as variable)
  address_space       = ["10.0.0.0/23"]                                 # Total address range for all subnets (512 IPs)
  location            = var.project_location                            # Azure region for VNet
  resource_group_name = azurerm_resource_group.project_rg.name          # Target resource group
}

# -------------------------------------------------------------------------------------------------
# DEFINE A SUBNET FOR VIRTUAL MACHINES / APPLICATION WORKLOADS
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "vm-subnet" {
  name                 = var.project_subnet                             # Subnet name (variable input)
  resource_group_name  = azurerm_resource_group.project_rg.name         # Must match the VNet’s RG
  virtual_network_name = azurerm_virtual_network.project-vnet.name      # Attach to parent VNet
  address_prefixes     = ["10.0.0.0/25"]                                 # Lower half of VNet CIDR (128 IPs)
}

# -------------------------------------------------------------------------------------------------
# DEFINE A DEDICATED SUBNET FOR AZURE BASTION
# REQUIRED NAME: MUST BE EXACTLY "AzureBastionSubnet"
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"                           # This name is MANDATORY for Bastion
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project-vnet.name
  address_prefixes     = ["10.0.1.0/25"]                                 # Upper half of VNet CIDR (128 IPs)
}

#############################################
# NETWORK SECURITY GROUP (NSG) FOR APP SUBNET
#############################################

resource "azurerm_network_security_group" "vm-nsg" {
  name                = "vm-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  # -------- Allow SSH access --------
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000                                    # Lower = higher priority
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # -------- Allow RDP (for Windows VMs) --------
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

##################################################
# NETWORK SECURITY GROUP (NSG) FOR BASTION SUBNET
##################################################

resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "bastion-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    destination_port_range     = "443"
    source_port_range          = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHAndRDPOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzurePlatformOutbound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    destination_port_range     = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  depends_on = [ azurerm_bastion_host.bastion-host ]
}

# -------------------------------------------------------------------------------------------------
# BIND THE BASTION SUBNET TO ITS SECURITY GROUP
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "bastion-nsg-assoc" {
  subnet_id                 = azurerm_subnet.bastion-subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
  depends_on = [ azurerm_bastion_host.bastion-host ]
}

# -------------------------------------------------------------------------------------------------
# BIND THE VM SUBNET TO ITS SECURITY GROUP
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "vm-nsg-assoc" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}

#############################################
# NAT GATEWAY CONFIGURATION FOR OUTBOUND ACCESS
#############################################

# -------------------------------------------------------------------------------------------------
# CREATE A NAT GATEWAY TO ENABLE OUTBOUND INTERNET ACCESS FROM PRIVATE VMs
# -------------------------------------------------------------------------------------------------
resource "azurerm_nat_gateway" "vm-nat-gateway" {
  name                = "vm-nat-gateway"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
  sku_name            = "Standard"                                      # Required SKU for production-grade NAT
}

# -------------------------------------------------------------------------------------------------
# STATIC PUBLIC IP FOR THE NAT GATEWAY
# -------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "vm_nat_public_ip" {
  name                = "vm-nat-public-ip"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
  allocation_method   = "Static"                                        # Ensures predictable public IP
  sku                 = "Standard"                                      # Required for use with NAT Gateway
}

# -------------------------------------------------------------------------------------------------
# ASSOCIATE THE PUBLIC IP TO THE NAT GATEWAY
# -------------------------------------------------------------------------------------------------
resource "azurerm_nat_gateway_public_ip_association" "vm_nat_assoc" {
  nat_gateway_id        = azurerm_nat_gateway.vm-nat-gateway.id
  public_ip_address_id  = azurerm_public_ip.vm_nat_public_ip.id
}

# -------------------------------------------------------------------------------------------------
# ATTACH THE NAT GATEWAY TO THE VM SUBNET FOR OUTBOUND ACCESS
# -------------------------------------------------------------------------------------------------
resource "azurerm_subnet_nat_gateway_association" "vm_subnet_nat" {
  subnet_id      = azurerm_subnet.vm-subnet.id
  nat_gateway_id = azurerm_nat_gateway.vm-nat-gateway.id
}
