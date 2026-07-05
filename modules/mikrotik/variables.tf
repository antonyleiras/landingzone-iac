variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# --- Storage do VHD (sempre criado) ---

variable "storage_account_name" {
  description = "Nome do storage account onde o VHD fixo do Mikrotik CHR e armazenado."
  type        = string
}

variable "container_name" {
  description = "Container de blobs onde o VHD fixo do CHR fica armazenado."
  type        = string
  default     = "vhds"
}

variable "vhd_blob_name" {
  description = "Nome do blob (VHD fixo) do CHR dentro do container."
  type        = string
  default     = "chr.vhd"
}

variable "upload_principal_object_id" {
  description = "Object ID do Service Principal (App Registration OIDC do GitHub Actions) que deve receber a role Storage Blob Data Contributor para subir o VHD. Deixe null para conceder manualmente pelo portal."
  type        = string
  default     = null
}

# --- VM do firewall (condicional) ---

variable "deploy_vm" {
  description = "Controla a criacao do managed disk (import) e da VM do firewall. So habilite depois que o VHD ja estiver no storage account."
  type        = bool
  default     = false
}

variable "vm_name" {
  type    = string
  default = "aslfwus2"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "disk_type" {
  description = "Tipo do managed disk importado do VHD."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "disk_size_gb" {
  description = "Tamanho do managed disk em GB. Deixe null para o Azure inferir a partir do VHD de origem."
  type        = number
  default     = null
}

variable "wan_subnet_id" {
  type = string
}

variable "lan_subnet_id" {
  type = string
}

variable "wan_private_ip" {
  description = "IP privado estatico da interface WAN do firewall."
  type        = string
  default     = "192.168.15.254"
}

variable "lan_private_ip" {
  description = "IP privado estatico da interface LAN do firewall."
  type        = string
  default     = "10.172.31.254"
}

variable "create_wan_public_ip" {
  description = "Se true, cria um Public IP Standard associado a interface WAN do firewall."
  type        = bool
  default     = true
}
