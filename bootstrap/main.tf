# Bootstrap do backend remoto compartilhado.
# Rode este modulo UMA UNICA VEZ, com state local, ANTES de qualquer outro
# projeto (landingzone-iac e avd-entra-iac usam o MESMO resource group e storage
# account de state, mudando apenas o "key" do blob).
#
#   cd bootstrap
#   terraform init
#   terraform apply

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  # Nome definido via variavel (nao gerado aleatoriamente) para o repositorio
  # poder ser reutilizado com clientes/subscriptions diferentes, cada um com
  # seu proprio nome previsivel de storage account.
  name                = var.tfstate_storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = var.location

  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
