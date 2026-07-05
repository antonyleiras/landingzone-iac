output "infra_resource_group_name" {
  value = azurerm_resource_group.infra.name
}

output "imagem_resource_group_name" {
  value = azurerm_resource_group.imagem.name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "wan_subnet_id" {
  value = module.networking.wan_subnet_id
}

output "lan_subnet_id" {
  value = module.networking.lan_subnet_id
}

output "avd_subnet_id" {
  description = "Usado como TF_VAR_avd_subnet_id / secret AVD_SUBNET_ID no projeto avd-entra-iac."
  value       = module.networking.avd_subnet_id
}

output "wan_nsg_id" {
  value = module.networking.wan_nsg_id
}

output "lan_nsg_id" {
  value = module.networking.lan_nsg_id
}

output "avd_nsg_id" {
  value = module.networking.avd_nsg_id
}

output "mikrotik_storage_account_name" {
  value = module.mikrotik.storage_account_name
}

output "mikrotik_vhd_upload_target_url" {
  description = "URL do blob de destino onde o workflow mikrotik-vhd-prepare.yml deve subir o VHD fixo do CHR."
  value       = module.mikrotik.vhd_upload_target_url
}

output "firewall_vm_id" {
  value = module.mikrotik.firewall_vm_id
}

output "firewall_wan_public_ip" {
  value = module.mikrotik.firewall_wan_public_ip
}

output "firewall_wan_private_ip" {
  value = module.mikrotik.firewall_wan_private_ip
}

output "firewall_lan_private_ip" {
  value = module.mikrotik.firewall_lan_private_ip
}
