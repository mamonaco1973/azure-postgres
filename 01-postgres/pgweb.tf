
# resource "random_string" "suffix" {
#   length  = 5
#   upper   = false
#   special = false
# }

# resource "azurerm_container_group" "pgweb" {
#   name                = "pgweb"
#   location            = data.azurerm_resource_group.project_rg.location
#   resource_group_name = data.azurerm_resource_group.project_rg.name
#   os_type             = "Linux"

#   ip_address_type = "Public"
#   dns_name_label  = "pgweb-${random_string.suffix.result}"

#   container {
#     name   = "pgweb"
#     image  = "sosedoff/pgweb:latest"
#     cpu    = "1.0"
#     memory = "1.0"

#     ports {
#       port     = 8081
#       protocol = "TCP"
#     }
#   }
# }
