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
