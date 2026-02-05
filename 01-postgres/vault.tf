# =================================================================================
# GENERATE RANDOM SUFFIX FOR KEY VAULT NAME
# =================================================================================
# Purpose:
#   - Ensure the Key Vault name is globally unique.
#
# Notes:
#   - Azure Key Vault names must be DNS-compliant and globally unique.
#   - Lowercase alphanumeric characters are safest across regions.
# =================================================================================
resource "random_string" "key_vault_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =================================================================================
# CREATE AZURE KEY VAULT FOR CREDENTIAL STORAGE
# =================================================================================
# Purpose:
#   - Centralize storage of sensitive credentials (DB and VM).
#   - Use Azure-native secrets management with RBAC.
#
# Notes:
#   - RBAC authorization is enabled (preferred over access policies).
#   - Purge protection is disabled to simplify teardown in lab environments.
# =================================================================================
resource "azurerm_key_vault" "credentials_key_vault" {
  name                       = "creds-kv-${random_string.key_vault_suffix.result}"
  resource_group_name        = azurerm_resource_group.project_rg.name
  location                   = var.project_location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
}

# =================================================================================
# ASSIGN KEY VAULT SECRETS OFFICER ROLE
# =================================================================================
# Purpose:
#   - Grant the current user or service principal permission to manage secrets.
#
# Notes:
#   - Scope is limited to this Key Vault only.
#   - Required before creating or updating secrets via Terraform.
# =================================================================================
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.credentials_key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =================================================================================
# GENERATE RANDOM PASSWORD FOR POSTGRESQL
# =================================================================================
# Purpose:
#   - Create a strong password for the PostgreSQL administrator account.
#
# Notes:
#   - Special characters are excluded for compatibility with scripts and tools.
# =================================================================================
resource "random_password" "postgres_password" {
  length  = 24
  special = false
}

# =================================================================================
# STORE POSTGRESQL CREDENTIALS IN KEY VAULT
# =================================================================================
# Purpose:
#   - Persist PostgreSQL credentials as a JSON-formatted secret.
#
# Notes:
#   - Secret creation depends on RBAC role assignment completion.
#   - JSON format allows structured retrieval by automation tools.
# =================================================================================
resource "azurerm_key_vault_secret" "postgres_secret" {
  name = "postgres-credentials"

  value = jsonencode({
    username = "postgres"
    password = random_password.postgres_password.result
  })

  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# =================================================================================
# GENERATE RANDOM PASSWORD FOR VM LOGIN
# =================================================================================
# Purpose:
#   - Create a strong local administrator password for the utility VM.
#
# Notes:
#   - Stored separately from database credentials for least-privilege access.
# =================================================================================
resource "random_password" "vm_password" {
  length  = 24
  special = false
}

# =================================================================================
# STORE VM CREDENTIALS IN KEY VAULT
# =================================================================================
# Purpose:
#   - Persist VM login credentials as a JSON-formatted secret.
#
# Notes:
#   - Enables secure retrieval for operators or automation without hardcoding.
# =================================================================================
resource "azurerm_key_vault_secret" "vm_secret" {
  name = "vm-credentials"

  value = jsonencode({
    username = "sysadmin"
    password = random_password.vm_password.result
  })

  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}
