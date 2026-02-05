#!/bin/bash
# =================================================================================
# FILE: destroy.sh
# =================================================================================
# Purpose:
#   - Tear down all PostgreSQL-related Azure infrastructure managed by Terraform.
#   - Cleanly destroy networking, compute, database, and supporting resources.
#
# Behavior:
#   - The script fails immediately on any error.
#   - Destructive actions are performed without interactive confirmation.
#
# WARNING:
#   - This script permanently deletes cloud resources.
#   - Ensure no dependent workloads are using this infrastructure.
# =================================================================================

# -----------------------------------------------------------------------------
# Enable strict shell behavior
#   -e  Exit immediately if a command exits with a non-zero status
#   -u  Treat unset variables as an error
#   -o pipefail  Fail if any command in a pipeline fails
# -----------------------------------------------------------------------------
set -euo pipefail

# =================================================================================
# STEP 1: DESTROY POSTGRES INFRASTRUCTURE
# =================================================================================
# Purpose:
#   - Remove all Terraform-managed resources under the 01-postgres directory.
#
# Notes:
#   - terraform destroy -auto-approve bypasses interactive prompts.
#   - State configuration must be accessible for successful teardown.
# =================================================================================
cd 01-postgres

terraform init
terraform destroy -auto-approve

cd ..

# =================================================================================
# END OF FILE
# =================================================================================
