# =================================================================================
# CREATE NETWORK INTERFACE FOR PGWEB VM
# =================================================================================
# Purpose:
#   - Provide a NIC for the pgweb utility VM.
#   - Attach the VM to the VM subnet and bind a public IP for inbound access.
#
# Notes:
#   - Private IP allocation is Dynamic (Azure assigns from the subnet pool).
#   - Public IP is Standard + Static to support a stable endpoint and DNS label.
# =================================================================================
resource "azurerm_network_interface" "pgweb_vm_nic" {
  name                = "pgweb-vm-nic"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pgweb_vm_public_ip.id
  }
}

# =================================================================================
# CREATE LINUX VM FOR PGWEB
# =================================================================================
# Purpose:
#   - Deploy a lightweight Ubuntu VM to run pgweb (web UI for PostgreSQL).
#   - Configure pgweb at build time using cloud-init (custom_data).
#
# Notes:
#   - Password authentication is enabled for simplicity; prefer SSH keys for
#     production.
#   - The VM depends on the PostgreSQL Flexible Server to ensure the endpoint
#     exists before cloud-init runs.
# =================================================================================
resource "azurerm_linux_virtual_machine" "pgweb_vm" {
  name                = "pgweb-vm"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  size           = "Standard_B1s"
  admin_username = "sysadmin"
  admin_password = random_password.vm_password.result

  # Password auth must be enabled when admin_password is provided.
  disable_password_authentication = false

  # -------------------------------------------------------------------------------
  # NETWORKING
  # -------------------------------------------------------------------------------
  network_interface_ids = [
    azurerm_network_interface.pgweb_vm_nic.id,
  ]

  # -------------------------------------------------------------------------------
  # STORAGE
  # -------------------------------------------------------------------------------
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # -------------------------------------------------------------------------------
  # IMAGE
  # -------------------------------------------------------------------------------
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # -------------------------------------------------------------------------------
  # BOOTSTRAP (CLOUD-INIT)
  # -------------------------------------------------------------------------------
  # Passes a rendered startup script to the VM. The script is responsible for:
  #   - Installing and configuring pgweb
  #   - Pointing pgweb to the PostgreSQL endpoint using generated credentials
  #
  # Azure requires custom_data to be base64-encoded.
  custom_data = base64encode(templatefile("./scripts/pgweb.sh.template", {
    PGPASSWORD = random_password.postgres_password.result
    PGENDPOINT = "postgres-instance-${random_string.suffix.result}.postgres.database.azure.com"
  }))

  depends_on = [
    azurerm_postgresql_flexible_server.postgres_instance,
  ]
}

# =================================================================================
# GENERATE SHORT SUFFIX FOR UNIQUE NAMING
# =================================================================================
# Purpose:
#   - Ensure globally-unique names where Azure enforces uniqueness (e.g., DNS).
#   - Reused for resources that need a stable but distinct identifier.
# =================================================================================
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# =================================================================================
# CREATE STATIC PUBLIC IP FOR PGWEB VM
# =================================================================================
# Purpose:
#   - Provide a stable public endpoint for the pgweb VM.
#   - Assign a DNS label for a predictable FQDN.
#
# Notes:
#   - Standard SKU is required for zone-resilient and production-grade behavior.
#   - allocation_method = "Static" keeps the IP constant across reboots.
# =================================================================================
resource "azurerm_public_ip" "pgweb_vm_public_ip" {
  name                = "pgweb-vm-public-ip"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pgweb-${random_string.suffix.result}"
}
