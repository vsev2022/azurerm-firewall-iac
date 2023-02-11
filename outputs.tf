output "resource_group_name" {
  value = azurerm_resource_group.rg_linux_vm.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.virtual_ubuntu_desktop_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.ubuntu_desktop_priv_key.private_key_pem
  sensitive = true
}