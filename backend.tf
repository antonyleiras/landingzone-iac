# Backend remoto (Azure Storage), compartilhado com o projeto avd-entra-iac
# (mesmo resource group/storage account, "key" de blob diferente). Valores
# reais passados via -backend-config, nao versionados aqui.
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate-eastus2" \
#     -backend-config="storage_account_name=<output do bootstrap>" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=landingzone-iac.tfstate"

terraform {
  backend "azurerm" {}
}
