variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "tfstate_resource_group_name" {
  description = "Resource group compartilhado de tfstate, usado tanto pelo landingzone-iac quanto pelo avd-entra-iac."
  type        = string
  default     = "rg-tfstate-eastus2"
}

variable "tfstate_storage_account_name" {
  description = "Nome do storage account de tfstate. Defina explicitamente (globalmente unico, 3-24 caracteres, minusculo/numeros) para poder reutilizar este projeto com outros clientes/subscriptions, cada um com seu proprio nome (ex: sttfstateclienteA, sttfstateclienteB)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.tfstate_storage_account_name))
    error_message = "tfstate_storage_account_name deve ter 3-24 caracteres, apenas letras minusculas e numeros."
  }
}
