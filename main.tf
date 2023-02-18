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