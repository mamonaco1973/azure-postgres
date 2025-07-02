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
# STEP 1: Provision bastion infrastructure (VNet, subnets, NICs, etc.)
#-------------------------------------------------------------------------------
cd 01-bastion                      # Navigate to Terraform infra folder
terraform init                      # Initialize Terraform plugins/backend
terraform apply -auto-approve       # Apply infrastructure configuration without prompt
cd ..                               # Return to root directory

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
