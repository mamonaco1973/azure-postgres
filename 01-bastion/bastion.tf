#############################################
# AZURE BASTION: PUBLIC IP + HOST
#############################################

# Public static IP for the Azure Bastion host
resource "azurerm_public_ip" "bastion-ip" {
  name                = "bastion-public-ip"                            # Unique name
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
  allocation_method   = "Static"                                       # Required for Bastion
  sku                 = "Standard"                                     # Standard SKU is mandatory
}

# Create the actual Bastion host resource
resource "azurerm_bastion_host" "bastion-host" {
  name                = "bastion-host"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  ip_configuration {
    name                 = "bastion-ip-config"                        # Internal config name
    subnet_id            = azurerm_subnet.bastion-subnet.id           # Must be "AzureBastionSubnet"
    public_ip_address_id = azurerm_public_ip.bastion-ip.id            # Link to the static IP created above
  }

  timeouts {
    create = "60m"  
    update = "60m"
    delete = "60m"
  }
}
