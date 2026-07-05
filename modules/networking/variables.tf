variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  description = "Nome explicito da VNet (ex: vnet-infra-eastus2)."
  type        = string
}

variable "vnet_address_space" {
  description = "Lista de espacos de enderecamento da VNet (pode ter mais de um bloco CIDR)."
  type        = list(string)
}

variable "wan_subnet_prefix" {
  type = string
}

variable "lan_subnet_prefix" {
  type = string
}

variable "avd_subnet_prefix" {
  type = string
}

variable "nsg_wan_name" {
  description = "Nome explicito do NSG da WANSubnet."
  type        = string
}

variable "nsg_lan_name" {
  description = "Nome explicito do NSG da LANSubnet."
  type        = string
}

variable "nsg_avd_name" {
  description = "Nome explicito do NSG da AVDSubnet."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
