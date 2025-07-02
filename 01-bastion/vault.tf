############################################
# RANDOM STRING: UNIQUE KEY VAULT SUFFIX
############################################
resource "random_string" "key_vault_suffix" {
  length  = 8                      # Generate an 8-character string
  special = false                  # Exclude special characters (for DNS-safe naming)
  upper   = false                  # Use only lowercase alphanumeric characters
                                   # Final result will be appended to Key Vault name for uniqueness
}

############################################
# AZURE KEY VAULT: CENTRALIZED SECRETS STORE
############################################
resource "azurerm_key_vault" "credentials_key_vault" {
  name                        = "creds-kv-${random_string.key_vault_suffix.result}"  
                                   # Dynamically generate a unique Key Vault name using the random string
  resource_group_name         = azurerm_resource_group.project_rg.name              
                                   # Place the Key Vault inside the existing resource group
  location                    = var.project_location             
                                   # Deploy in the same region as the resource group
  sku_name                    = "standard"                                            
                                   # Use Standard SKU (most common for general-purpose secrets management)
  tenant_id                   = data.azurerm_client_config.current.tenant_id          
                                   # Azure AD tenant ID from the currently authenticated user context
  purge_protection_enabled    = false                                                 
                                   # Disable purge protection (irreversible deletion allowed)
  enable_rbac_authorization   = true                                                  
                                   # Use RBAC (role-based access control) instead of Access Policies
}

############################################
# RBAC ASSIGNMENT: ALLOW USER TO MANAGE SECRETS
############################################
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.credentials_key_vault.id                        
                                   # Apply the role at the Key Vault resource level
  role_definition_name = "Key Vault Secrets Officer"                                  
                                   # Grants permissions to read/write secrets (not certificates or keys)
  principal_id         = data.azurerm_client_config.current.object_id                 
                                   # Assign role to currently authenticated user or service principal
}

#################################################
# RANDOM PASSWORD: SECURE CREDENTIAL FOR LINUX VM
#################################################
resource "random_password" "vm_password" {
  length  = 24                    # Password length (strong enough for automation)
  special = false                 # No special characters (avoids compatibility issues with some scripts)
}

############################################
# KEY VAULT SECRET: STORE PACKER CREDENTIALS
############################################
resource "azurerm_key_vault_secret" "linux_vm_secret" {
  name         = "vm-credentials"                                                  
                                   # Secret name inside the Key Vault
  value        = jsonencode({                                                          
    username = "sysadmin"                                                                
    password = random_password.vm_password.result                                        
  })                                                                                   
                                   # Store a JSON-encoded object with username and generated password

  key_vault_id = azurerm_key_vault.credentials_key_vault.id                                 
                                   # Reference the ID of the Key Vault created earlier
  depends_on   = [ azurerm_role_assignment.kv_role_assignment ]                        
                                   # Ensure role assignment is completed before attempting to write secrets

  content_type = "application/json"                                                    
                                   # Add metadata describing the format of the stored secret value
}
