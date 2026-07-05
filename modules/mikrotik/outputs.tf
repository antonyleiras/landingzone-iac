output "storage_account_name" {
  value = azurerm_storage_account.vhds.name
}

output "container_name" {
  value = azurerm_storage_container.vhds.name
}

output "vhd_upload_target_url" {
  description = "URL do blob de destino onde o workflow mikrotik-vhd-prepare.yml deve subir o VHD fixo do CHR."
  value       = "${azurerm_storage_account.vhds.primary_blob_endpoint}${azurerm_storage_container.vhds.name}/${var.vhd_blob_name}"
}

output "firewall_vm_id" {
  value = try(azurerm_virtual_machine.mikrotik[0].id, null)
}

output "firewall_wan_public_ip" {
  value = try(azurerm_public_ip.wan[0].ip_address, null)
}

output "firewall_wan_private_ip" {
  value = try(azurerm_network_interface.wan[0].ip_configuration[0].private_ip_address, null)
}

output "firewall_lan_private_ip" {
  value = try(azurerm_network_interface.lan[0].ip_configuration[0].private_ip_address, null)
}
