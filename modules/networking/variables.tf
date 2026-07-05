variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  description = "Usado apenas na nomenclatura dos NSGs (nsg-<name_prefix>-wan/lan/avd)."
  type        = string
}

variable "vnet_name" {
  description = "Nome explicito da VNet (ex: vnet-infra-eastus2)."
  type        = string
}

variable "vnet_address_space" {
  type = string
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

variable "tags" {
  type    = map(string)
  default = {}
}
