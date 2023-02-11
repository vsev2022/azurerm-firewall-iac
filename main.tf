#locals{
  # Get terraform.io notifications ip range and add client_ip to local.ip_rules
  # Make sure to allow the backend client ip, in this example terraform cloud is used for backend state
  #terraform_ip_range =[for i in data.tfe_ip_ranges.addresses.notifications : replace(i, "/32", "")]
  #client_ip = chomp(data.http.myip.response_body)
  #ip_rules = concat(local.terraform_ip_range, [local.client_ip])
#}

# Create resource group for virtual machine
resource "azurerm_resource_group" "rg_linux_vm" {
  name     = var.resource_group_name == "" ? module.resource_group_label.id : var.resource_group_name
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------------------------------------------------

# Create virtual network
resource "azurerm_virtual_network" "tf_vnetwork" {
  name                = "tf-vnetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_linux_vm.location
  resource_group_name = azurerm_resource_group.rg_linux_vm.name
}

# Create subnet
resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet-1"
  resource_group_name  = azurerm_resource_group.rg_linux_vm.name
  virtual_network_name = azurerm_virtual_network.tf_vnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "nic_01_pip" {
  name                = "nic-01-pip"
  location            = azurerm_resource_group.rg_linux_vm.location
  resource_group_name = azurerm_resource_group.rg_linux_vm.name
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "virtual_machine_nsg" {
  name                = "virtual-machine-nsg"
  location            = azurerm_resource_group.rg_linux_vm.location
  resource_group_name = azurerm_resource_group.rg_linux_vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.client_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.client_ip
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic_01" {
  name                = "nic-01"
  location            = azurerm_resource_group.rg_linux_vm.location
  resource_group_name = azurerm_resource_group.rg_linux_vm.name

  ip_configuration {
    name                          = "nic-01-configuration"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nic_01_pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic_01.id
  network_security_group_id = azurerm_network_security_group.virtual_machine_nsg.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage Account
# ---------------------------------------------------------------------------------------------------------------------

# Generate random text for a unique storage account name
/* resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg_linux_vm.name
  }
  byte_length = 8
} */

# Create storage account for boot diagnostics
/* resource "azurerm_storage_account" "vm_boot_diag_storage" {
  # checkov:skip=CKV_AZURE_59: Checkov misses that the field 'allow_blob_public_access' is renamed to 'allow_nested_items_to_be_public' and is set correctly
  # Azure Resource Manager: 3.0 Upgrade Guide - The field 'allow_blob_public_access' is renamed to 'allow_nested_items_to_be_public'
  name                            = "diag${random_id.randomId.hex}"
  location                        = azurerm_resource_group.rg_linux_vm.location
  resource_group_name             = azurerm_resource_group.rg_linux_vm.name
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true # enable to access the storage account with key
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true

  identity {
    type = "SystemAssigned"
  }

  queue_properties {
    logging {
      delete                = true
      read                  = true
      version               = "2.0"
      write                 = true
      retention_policy_days = "10"
    }
  }
} */

# ---------------------------------------------------------------------------------------------------------------------
# Azure KeyVault
# ---------------------------------------------------------------------------------------------------------------------

/* resource "azurerm_key_vault" "virtual_machine_kv" {
  # checkov:skip=CKV_AZURE_109: Checkov misses that default_action = "Deny" is already set correct
  name                       = module.key_vault_label.id
  location                   = azurerm_resource_group.rg_linux_vm.location
  resource_group_name        = azurerm_resource_group.rg_linux_vm.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
    ip_rules       = [for i in local.ip_rules : i] 
  }
} */

#resource "azurerm_key_vault_access_policy" "storage" {
#  key_vault_id = azurerm_key_vault.virtual_machine_kv.id
#  tenant_id    = data.azurerm_client_config.current.tenant_id
#  object_id    = azurerm_storage_account.vm_boot_diag_storage.identity[0].principal_id

#  key_permissions    = ["Get", "Create", "List", "Restore", "Recover", "UnwrapKey", "WrapKey", "Purge", "Encrypt", "Decrypt", "Sign", "Verify", ]
#  secret_permissions = ["Get", ]

  /* depends_on = [
    azurerm_storage_container.tfstate
  ] */
#}

/* resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.virtual_machine_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  lifecycle {
    create_before_destroy = true
  }

  key_permissions         = var.kv-key-permissions-full
  secret_permissions      = var.kv-secret-permissions-full
  certificate_permissions = var.kv-certificate-permissions-full
  storage_permissions     = var.kv-storage-permissions-full
} */

# This is a basic KeyVault with standard SKU and HSM can only be used with a premium SKU KeyVault
# https://learn.microsoft.com/en-us/azure/key-vault/keys/about-keys
/* resource "azurerm_key_vault_key" "virtual_machine_kv_key" {
  # checkov:skip=CKV_AZURE_112: Ensure key vault key is backed by HSM
  name            = module.key_vault_label.id
  key_vault_id    = azurerm_key_vault.virtual_machine_kv.id
  key_type        = "RSA"
  key_size        = 2048
  expiration_date = "2023-12-31T23:59:59Z"
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey", ]

  depends_on = [
    azurerm_key_vault_access_policy.client,
    azurerm_key_vault_access_policy.storage,
  ]
}

resource "azurerm_storage_account_customer_managed_key" "tfstate" {
  storage_account_id = azurerm_storage_account.vm_boot_diag_storage.id
  key_vault_id       = azurerm_key_vault.virtual_machine_kv.id
  key_name           = azurerm_key_vault_key.virtual_machine_kv_key.name
  key_version        = null # null enables automatic key rotation
} */

# ---------------------------------------------------------------------------------------------------------------------
# Virtual Machine
# ---------------------------------------------------------------------------------------------------------------------

# Create an SSH key
resource "tls_private_key" "ubuntu_desktop_priv_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "virtual_ubuntu_desktop_vm" {
  name                  = var.linux_machine_name
  location              = azurerm_resource_group.rg_linux_vm.location
  resource_group_name   = azurerm_resource_group.rg_linux_vm.name
  network_interface_ids = [azurerm_network_interface.nic_01.id]
  size                  = var.vm_size

  os_disk {
    name                 = "${var.linux_machine_name}_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.source_imgage_reference_publisher
    offer     = var.source_imgage_reference_offer
    sku       = var.source_imgage_reference_sku
    version   = var.source_imgage_reference_version
  }

/*   plan {
    name = var.source_plan_name
    publisher = var.source_plan_publisher
    product = var.source_plan_product
  } */

  computer_name                   = var.linux_machine_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ubuntu_desktop_priv_key.public_key_openssh
  }

  /* boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vm_boot_diag_storage.primary_blob_endpoint
  } */
  allow_extension_operations = false
}