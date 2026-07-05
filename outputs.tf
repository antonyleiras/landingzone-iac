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
