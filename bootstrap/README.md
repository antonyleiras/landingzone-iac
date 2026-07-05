# Bootstrap do backend remoto (compartilhado)

Cria, com state **local**, o Resource Group `rg-tfstate-eastus2` + Storage
Account usados como backend remoto (`azurerm`) por **ambos** os projetos:
`landingzone-iac` e `avd-entra-iac`. Rode apenas uma vez, antes do primeiro
`terraform init` em qualquer um dos dois repositórios.

```bash
cd bootstrap
terraform init
terraform apply \
  -var="subscription_id=<sua-subscription-id>" \
  -var="tenant_id=<seu-tenant-id>" \
  -var="tfstate_storage_account_name=<nome-unico-globalmente, ex: sttfstatecliente1>"
```

`tfstate_storage_account_name` é obrigatório e não é mais gerado
aleatoriamente — defina um nome previsível por cliente/subscription (esse
projeto é reutilizável para múltiplos clientes, cada um com seu próprio
storage account de state).

Anote os outputs — serão usados no `-backend-config` dos dois projetos e
nos secrets `TFSTATE_RESOURCE_GROUP` / `TFSTATE_STORAGE_ACCOUNT` de cada
repositório no GitHub Actions. Cada projeto usa um `key` de blob diferente:

- `landingzone-iac` → `key=landingzone-iac.tfstate`
- `avd-entra-iac` → `key=avd-entra-iac.tfstate`
