variable "subscription_id" {
  description = "ID da subscription Azure onde a landing zone sera provisionada."
  type        = string
}

variable "tenant_id" {
  description = "ID do tenant Microsoft Entra ID."
  type        = string
}

variable "location" {
  description = "Regiao Azure para os recursos."
  type        = string
  default     = "eastus2"
}

variable "name_prefix" {
  description = "Prefixo curto usado na nomenclatura dos recursos de rede (vnet, nsgs...)."
  type        = string
  default     = "lz-eastus2"
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos."
  type        = map(string)
  default     = {}
}

# --- Resource groups fixos ---

variable "infra_resource_group_name" {
  description = "Resource group com todos os recursos de infraestrutura/rede da landing zone."
  type        = string
  default     = "rg-infra-eastus2"
}

variable "imagem_resource_group_name" {
  description = "Resource group reservado para os recursos de golden image (Azure Compute Gallery, definicoes de imagem). Fica vazio por enquanto."
  type        = string
  default     = "rg-imagem-eastus2"
}

# --- Rede ---

variable "vnet_name" {
  description = "Nome explicito da VNet."
  type        = string
  default     = "vnet-infra-eastus2"
}

variable "vnet_address_space" {
  description = "Espaco de enderecamento da VNet da landing zone."
  type        = string
  default     = "10.20.0.0/22"
}

variable "wan_subnet_prefix" {
  description = "Prefixo da WANSubnet."
  type        = string
  default     = "10.20.0.0/24"
}

variable "lan_subnet_prefix" {
  description = "Prefixo da LANSubnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "avd_subnet_prefix" {
  description = "Prefixo da AVDSubnet (usada pelo projeto avd-entra-iac para os session hosts e o storage do FSLogix)."
  type        = string
  default     = "10.20.2.0/24"
}
