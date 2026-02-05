#!/bin/bash
# =================================================================================
# FILE: check_env.sh
# =================================================================================
# Purpose:
#   - Validate that all required CLI tools are installed and available in PATH.
#   - Verify required Azure Service Principal environment variables are set.
#   - Authenticate to Azure using a Service Principal.
#
# Behavior:
#   - The script exits immediately on any validation or authentication failure.
# =================================================================================

# -----------------------------------------------------------------------------
# Enable strict shell behavior
#   -e  Exit immediately if a command exits with a non-zero status
#   -u  Treat unset variables as an error
#   -o pipefail  Fail if any command in a pipeline fails
# -----------------------------------------------------------------------------
set -euo pipefail

# =================================================================================
# VALIDATE REQUIRED COMMANDS
# =================================================================================
# Purpose:
#   - Ensure all required CLI tools are available before running Terraform.
# =================================================================================
echo "NOTE: Validating that required commands are found in PATH."

commands=(
  az
  terraform
  jq
)

for cmd in "${commands[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command '${cmd}' not found in PATH."
    exit 1
  fi
  echo "NOTE: '${cmd}' is available."
done

echo "NOTE: All required commands are available."

# =================================================================================
# VALIDATE REQUIRED ENVIRONMENT VARIABLES
# =================================================================================
# Purpose:
#   - Confirm Azure Service Principal credentials are present.
#
# Notes:
#   - These variables are required for non-interactive Terraform authentication
#     with the AzureRM provider.
# =================================================================================
echo "NOTE: Validating required environment variables."

required_vars=(
  ARM_CLIENT_ID
  ARM_CLIENT_SECRET
  ARM_SUBSCRIPTION_ID
  ARM_TENANT_ID
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Environment variable '${var}' is not set or is empty."
    exit 1
  fi
  echo "NOTE: '${var}' is set."
done

echo "NOTE: All required environment variables are set."

# =================================================================================
# AUTHENTICATE TO AZURE USING SERVICE PRINCIPAL
# =================================================================================
# Purpose:
#   - Verify credentials by performing a non-interactive Azure login.
#
# Notes:
#   - Output is suppressed to avoid leaking sensitive information.
#   - A failure here indicates invalid credentials or tenant configuration.
# =================================================================================
echo "NOTE: Authenticating to Azure using Service Principal."

az login \
  --service-principal \
  --username "${ARM_CLIENT_ID}" \
  --password "${ARM_CLIENT_SECRET}" \
  --tenant "${ARM_TENANT_ID}" \
  >/dev/null 2>&1

echo "NOTE: Azure authentication successful."

# =================================================================================
# END OF FILE
# =================================================================================
