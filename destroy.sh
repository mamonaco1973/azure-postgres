#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 1: Destroy postgres infrastructure (VNet, Subnet, NICs, NSGs, etc.)
#-------------------------------------------------------------------------------
cd 02-postgres                     # Go to base infra config
terraform init                     # Initialize Terraform plugins/modules
terraform destroy -auto-approve    # Destroy all foundational Azure resources
cd ..                              # Return to root

cd 01-acr
terraform init                     # Initialize ACR plugins/modules
terraform destroy -auto-approve    # Destroy all foundational Azure resources
cd ..                              # Return to root

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
