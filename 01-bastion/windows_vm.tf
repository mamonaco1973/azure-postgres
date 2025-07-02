# -------------------------------------------------------------------------------------------------
# DEFINE A NETWORK INTERFACE (NIC) FOR THE WINDOWS VM TO CONNECT TO THE VIRTUAL NETWORK
# -------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "windows-vm-nic" {
  name                = "windows-vm-nic"                           # Unique NIC name for Windows VM
  location            = var.project_location                       # Match with VM and resource group region
  resource_group_name = azurerm_resource_group.project_rg.name     # Attach NIC to the correct resource group

  # -----------------------------
  # CONFIGURE IP SETTINGS FOR NIC
  # -----------------------------
  ip_configuration {
    name                          = "internal"                     # Arbitrary label for this IP config
    subnet_id                     = azurerm_subnet.vm-subnet.id    # Link NIC to existing subnet
    private_ip_address_allocation = "Dynamic"                      # Let Azure assign a private IP automatically
  }
}

# -------------------------------------------------------------------------------------------------
# CREATE A WINDOWS SERVER 2022 VIRTUAL MACHINE AND ASSOCIATE IT WITH THE NIC ABOVE
# -------------------------------------------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "windows-vm" {
  name                = "windows-vm"                                # VM name as shown in Azure
  location            = var.project_location                        # Match the NIC and resource group region
  resource_group_name = azurerm_resource_group.project_rg.name      # Same RG as NIC and other resources

  size                = "Standard_B2ms"                             # VM size with enough CPU/RAM for typical Windows use
  admin_username      = "sysadmin"                                  # Admin username to RDP into the box
  admin_password      = random_password.vm_password.result          # Secure password generated from Terraform random_password

  # ----------------------------------------
  # ASSOCIATE THE VM WITH THE NIC DEFINED ABOVE
  # ----------------------------------------
  network_interface_ids = [
    azurerm_network_interface.windows-vm-nic.id                     # Only one NIC in this example
  ]

  # --------------------------
  # DEFINE THE OS DISK SETTINGS
  # --------------------------
  os_disk {
    caching              = "ReadWrite"                              # Enable disk-level caching for performance
    storage_account_type = "Standard_LRS"                           # Use standard, locally-redundant disk storage
  }

  # ------------------------------------------------------
  # USE MICROSOFT’S OFFICIAL WINDOWS SERVER 2022 IMAGE
  # ------------------------------------------------------
  source_image_reference {
    publisher = "MicrosoftWindowsServer"                           # Publisher of official Windows images
    offer     = "WindowsServer"                                     # Windows Server base OS
    sku       = "2022-Datacenter"                                   # Datacenter edition of Windows Server 2022
    version   = "latest"                                            # Always deploy the most recent image version
  }

  # -----------------------------
  # ENABLE VM-SPECIFIC FEATURES
  # -----------------------------
  provision_vm_agent        = true                                  # REQUIRED for VM extensions, diagnostics, and automation
  enable_automatic_updates  = true                                  # Let Windows handle patching automatically
}
