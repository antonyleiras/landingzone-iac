locals {
  common_tags = merge(var.tags, {
    project    = "landingzone-iac"
    managed_by = "terraform"
  })
}

resource "azurerm_resource_group" "infra" {
  name     = var.infra_resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Reservado para golden image / Azure Compute Gallery. Sem recursos dentro
# por enquanto — o modulo de imagem sera adicionado quando o processo de
# build (Packer / Azure Image Builder / Sysprep manual) for definido.
resource "azurerm_resource_group" "imagem" {
  name     = var.imagem_resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.infra.name
  location            = var.location

  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space
  wan_subnet_prefix  = var.wan_subnet_prefix
  lan_subnet_prefix  = var.lan_subnet_prefix
  avd_subnet_prefix  = var.avd_subnet_prefix

  nsg_wan_name = var.nsg_wan_name
  nsg_lan_name = var.nsg_lan_name
  nsg_avd_name = var.nsg_avd_name

  tags = local.common_tags
}

module "mikrotik" {
  source = "./modules/mikrotik"

  resource_group_name = azurerm_resource_group.infra.name
  location            = var.location

  storage_account_name       = var.mikrotik_storage_account_name
  container_name             = var.mikrotik_vhd_container_name
  vhd_blob_name              = var.mikrotik_vhd_blob_name
  upload_principal_object_id = var.mikrotik_upload_principal_object_id

  deploy_vm            = var.deploy_mikrotik_firewall
  vm_name              = var.firewall_name
  vm_size              = var.firewall_vm_size
  disk_type            = var.firewall_disk_type
  wan_subnet_id        = module.networking.wan_subnet_id
  lan_subnet_id        = module.networking.lan_subnet_id
  wan_private_ip       = var.firewall_wan_private_ip
  lan_private_ip       = var.firewall_lan_private_ip
  create_wan_public_ip = var.firewall_create_wan_public_ip

  tags = local.common_tags
}
