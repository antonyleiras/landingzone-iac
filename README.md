# landingzone-iac

Provisionamento via Terraform da infraestrutura base (rede) para o ambiente
Azure, aplicado **antes** do projeto `avd-entra-iac`. Este repositório não
conhece nada sobre AVD — só entrega a rede e reserva os resource groups que
os outros projetos vão consumir.

## Arquitetura

```
Subscription
├── rg-tfstate-eastus2   -> Storage Account de state (bootstrap, compartilhado
│                            com o projeto avd-entra-iac)
├── rg-infra-eastus2     -> vnet-infra-eastus2 + WANSubnet + LANSubnet + AVDSubnet + 3 NSGs
└── rg-imagem-eastus2    -> reservado para golden image / Azure Compute
                             Gallery (sem recursos ainda)
```

A VNet tem 3 blocos de endereçamento (`address_space` é uma lista), porque as
subnets pedidas caem em faixas não contíguas:

| Bloco da VNet | Cobre |
|---|---|
| `192.168.14.0/23` | `WANSubnet` |
| `10.172.28.0/22` | `LANSubnet` |
| `10.172.32.0/24` | `AVDSubnet` |

> O range original pensado para LAN+AVD (`10.172.30.0/22`) não é um limite
> de rede válido para `/22` (o terceiro octeto precisa ser múltiplo de 4) e
> também não cobria a `AVDSubnet` (`10.172.32.0/24` fica fora desse `/22`).
> Por isso o espaço foi dividido em dois blocos.

| Subnet | CIDR | Uso pretendido | NSG |
|---|---|---|---|
| `WANSubnet` | `192.168.15.0/24` | Saída/entrada externa (gateway, firewall, etc. quando existirem) | `nsg-wan-eastus2` |
| `LANSubnet` | `10.172.31.0/24` | Tráfego interno geral | `nsg-lan-eastus2` |
| `AVDSubnet` | `10.172.32.0/24` | Session hosts e storage FSLogix do projeto `avd-entra-iac` | `nsg-avd-eastus2` |

## Pré-requisitos

1. Subscription Azure já existente.
2. Terraform >= 1.7, Azure CLI (para uso local).
3. Um App Registration no Entra ID com federated credential (OIDC) para o
   GitHub Actions.

## Passo a passo

### 1. Bootstrap do backend remoto (uma única vez, compartilhado)

```bash
cd bootstrap
terraform init
terraform apply \
  -var="subscription_id=<sub-id>" \
  -var="tenant_id=<tenant-id>" \
  -var="tfstate_storage_account_name=<nome-unico-globalmente, ex: sttfstatecliente1>"
```

`tfstate_storage_account_name` é obrigatório (sem geração aleatória), para
que este projeto possa ser reaplicado para clientes/subscriptions diferentes
com nomes previsíveis. Anote os outputs `resource_group_name` (deve ser
`rg-tfstate-eastus2`) e `storage_account_name` — serão usados por **este**
projeto e pelo `avd-entra-iac`.

### 2. App Registration com OIDC para o GitHub Actions

```bash
az ad app create --display-name "gh-oidc-landingzone-iac"
az ad sp create --id <appId>

az role assignment create \
  --assignee <appId> \
  --role "Contributor" \
  --scope "/subscriptions/<sub-id>"

az ad app federated-credential create \
  --id <appId> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:antonyleiras/landingzone-iac:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Repita com `"subject": "repo:antonyleiras/landingzone-iac:pull_request"` e
`"name": "github-pr"` para habilitar o `plan` em Pull Requests.

### 3. Secrets do repositório (Settings > Secrets and variables > Actions)

| Secret | Descrição |
|---|---|
| `AZURE_CLIENT_ID` | App ID do App Registration OIDC deste projeto |
| `AZURE_TENANT_ID` | Tenant ID do Entra ID |
| `AZURE_SUBSCRIPTION_ID` | ID da subscription alvo |
| `TFSTATE_RESOURCE_GROUP` | `rg-tfstate-eastus2` (output do bootstrap) |
| `TFSTATE_STORAGE_ACCOUNT` | Output do bootstrap |

Configure também o **Environment** `production` (Settings > Environments)
com aprovadores obrigatórios.

### 4. Rodar localmente (opcional, antes do CI)

```bash
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars

terraform init \
  -backend-config="resource_group_name=rg-tfstate-eastus2" \
  -backend-config="storage_account_name=<output do bootstrap>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=landingzone-iac.tfstate"

terraform plan
terraform apply
```

### 5. Depois do apply

Pegue o output `avd_subnet_id` (`terraform output avd_subnet_id`) e use como
`AVD_SUBNET_ID` (secret) / `avd_subnet_id` (variável) no projeto
`avd-entra-iac`, que deve ser aplicado em seguida.

## Próximos passos

- Módulo de golden image (Azure Compute Gallery + Image Definition) dentro
  de `rg-imagem-eastus2`, quando o processo de build da imagem for
  definido.
- Avaliar Private Endpoints / Azure Firewall na `WANSubnet` se a topologia
  evoluir para hub-and-spoke.
