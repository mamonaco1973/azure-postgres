#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 0: Run environment validation script
#-------------------------------------------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1  # Hard exit if environment validation fails
fi

#-------------------------------------------------------------------------------
# STEP 1: Provision postgres infrastructure (VNet, subnets, NICs, etc.)
#-------------------------------------------------------------------------------

default_domain=$(az rest --method get --url "https://graph.microsoft.com/v1.0/domains" --query "value[?isDefault].id" --output tsv)
echo "NOTE: Default domain for account is $default_domain"

cd 02-postgres                         # Navigate to Terraform infra folder
terraform init                         # Initialize Terraform plugins/backend
terraform apply \
-var="azure_domain=$default_domain" \
 -auto-approve                         # Apply infrastructure configuration without prompt
cd ..                                  # Return to root directory

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
