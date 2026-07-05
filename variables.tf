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
  description = <<-EOT
    Lista de espacos de enderecamento da VNet. Sao dois blocos separados
    porque o segundo bloco original (10.172.30.0/22) nao e um limite de
    rede valido para /22 (30 nao e multiplo de 4) e tambem nao cobria a
    AVDSubnet (10.172.32.0/24). Foi dividido em 10.172.28.0/22 (cobre
    .28-.31, contem a LANSubnet) + 10.172.32.0/24 (contem a AVDSubnet).
  EOT
  type    = list(string)
  default = ["192.168.14.0/23", "10.172.28.0/22", "10.172.32.0/24"]
}

variable "wan_subnet_prefix" {
  description = "Prefixo da WANSubnet."
  type        = string
  default     = "192.168.15.0/24"
}

variable "lan_subnet_prefix" {
  description = "Prefixo da LANSubnet."
  type        = string
  default     = "10.172.31.0/24"
}

variable "avd_subnet_prefix" {
  description = "Prefixo da AVDSubnet (usada pelo projeto avd-entra-iac para os session hosts e o storage do FSLogix)."
  type        = string
  default     = "10.172.32.0/24"
}

variable "nsg_wan_name" {
  description = "Nome explicito do NSG da WANSubnet."
  type        = string
  default     = "nsg-wan-eastus2"
}

variable "nsg_lan_name" {
  description = "Nome explicito do NSG da LANSubnet."
  type        = string
  default     = "nsg-lan-eastus2"
}

variable "nsg_avd_name" {
  description = "Nome explicito do NSG da AVDSubnet."
  type        = string
  default     = "nsg-avd-eastus2"
}
