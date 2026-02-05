#!/bin/bash
# =================================================================================
# FILE: apply.sh
# =================================================================================
# Purpose:
#   - Validate the local environment.
#   - Deploy PostgreSQL infrastructure using Terraform.
#   - Run post-deployment validation checks.
#
# Behavior:
#   - The script fails immediately on any error.
#   - Unset variables and failed pipeline commands are treated as fatal.
# =================================================================================

# -----------------------------------------------------------------------------
# Enable strict shell behavior
#   -e  Exit immediately if a command exits with a non-zero status
#   -u  Treat unset variables as an error
#   -o pipefail  Fail if any command in a pipeline fails
# -----------------------------------------------------------------------------
set -euo pipefail

# =================================================================================
# STEP 0: VALIDATE LOCAL ENVIRONMENT
# =================================================================================
# Purpose:
#   - Ensure all required tools, credentials, and variables are present
#     before attempting deployment.
#
# Notes:
#   - check_env.sh is expected to exit non-zero on failure.
#   - With `set -e` enabled, any failure here will immediately abort.
# =================================================================================
./check_env.sh

# =================================================================================
# STEP 1: DEPLOY POSTGRES INFRASTRUCTURE
# =================================================================================
# Purpose:
#   - Provision core infrastructure including:
#       * Virtual network and subnets
#       * Network interfaces and security groups
#       * PostgreSQL Flexible Server and supporting resources
#
# Notes:
#   - -auto-approve disables interactive confirmation prompts.
# =================================================================================
cd 01-postgres

terraform init
terraform apply -auto-approve

cd ..

# =================================================================================
# STEP 2: RUN POST-DEPLOYMENT VALIDATION
# =================================================================================
# Purpose:
#   - Verify that deployed resources are reachable and operational.
#   - Print endpoints and basic connectivity information.
#
# Notes:
#   - Any validation failure will terminate the script immediately.
# =================================================================================
echo ""
./validate.sh

# =================================================================================
# END OF FILE
# =================================================================================
