# Use this data source to access the configuration of the AzureRM provider.
data "azurerm_client_config" "current" {}

# Get our public IP address
data "http" "myip" {
  url = "https://icanhazip.com/"
}

# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/ip_ranges
# https://developer.hashicorp.com/terraform/cloud-docs/api-docs/ip-ranges
data "tfe_ip_ranges" "addresses" {}