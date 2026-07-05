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

# Lista de espacos de enderecamento da VNet. LANSubnet (10.172.29.0/24) e
# AVDSubnet (10.172.30.0/24) agora cabem dentro do mesmo bloco
# 10.172.28.0/22 (cobre .28-.31), entao o bloco separado 10.172.32.0/24
# que existia antes para a AVDSubnet foi removido por nao ser mais
# necessario.
variable "vnet_address_space" {
  description = "Lista de blocos CIDR de enderecamento da VNet."
  type        = list(string)
  default     = ["192.168.14.0/23", "10.172.28.0/22"]
}

variable "wan_subnet_prefix" {
  description = "Prefixo da WANSubnet."
  type        = string
  default     = "192.168.15.0/24"
}

variable "lan_subnet_prefix" {
  description = "Prefixo da LANSubnet."
  type        = string
  default     = "10.172.29.0/24"
}

variable "avd_subnet_prefix" {
  description = "Prefixo da AVDSubnet (usada pelo projeto avd-entra-iac para os session hosts e o storage do FSLogix)."
  type        = string
  default     = "10.172.30.0/24"
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

# --- Firewall Mikrotik CHR (aslfwus2) ---

variable "mikrotik_storage_account_name" {
  description = "Nome do storage account onde o VHD fixo do Mikrotik CHR e armazenado (upload feito pelo workflow mikrotik-vhd-prepare.yml)."
  type        = string
  default     = "stgacctaslinfraus2"
}

variable "mikrotik_vhd_container_name" {
  description = "Container de blobs onde o VHD fixo do CHR fica armazenado."
  type        = string
  default     = "vhds"
}

variable "mikrotik_vhd_blob_name" {
  description = "Nome do blob (VHD fixo) do CHR dentro do container."
  type        = string
  default     = "chr.vhd"
}

variable "mikrotik_upload_principal_object_id" {
  description = "Object ID do Service Principal (App Registration OIDC do GitHub Actions) que deve receber a role Storage Blob Data Contributor para subir o VHD via workflow. Deixe null para conceder manualmente pelo portal."
  type        = string
  default     = null
}

# Controla a criacao do managed disk (import) e da VM do firewall. Deixe
# false ate o VHD ja estar no storage account (rode o workflow
# mikrotik-vhd-prepare.yml antes de virar true).
variable "deploy_mikrotik_firewall" {
  type    = bool
  default = true
}

variable "firewall_name" {
  description = "Nome da VM do firewall Mikrotik CHR."
  type        = string
  default     = "aslfwus2"
}

variable "firewall_vm_size" {
  description = "SKU da VM do firewall Mikrotik CHR."
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "firewall_disk_type" {
  description = "Tipo do managed disk importado do VHD do firewall."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "firewall_wan_private_ip" {
  description = "IP privado estatico da interface WAN do firewall."
  type        = string
  default     = "192.168.15.254"
}

variable "firewall_lan_private_ip" {
  description = "IP privado estatico da interface LAN do firewall."
  type        = string
  default     = "10.172.29.254"
}

variable "firewall_create_wan_public_ip" {
  description = "Se true, cria um Public IP Standard associado a interface WAN do firewall."
  type        = bool
  default     = true
}
