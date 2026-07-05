# landingzone-iac

Provisionamento via Terraform da infraestrutura base (rede + firewall) para o
ambiente Azure, aplicado **antes** do projeto `avd-entra-iac`. Este
repositório não conhece nada sobre AVD — entrega a rede, o firewall de borda
e reserva os resource groups que os outros projetos vão consumir.

## Arquitetura

```
Subscription
├── rg-tfstate-eastus2   -> Storage Account de state (bootstrap, compartilhado
│                            com o projeto avd-entra-iac)
├── rg-infra-eastus2     -> vnet-infra-eastus2 + WANSubnet + LANSubnet + AVDSubnet + 3 NSGs
│                            + storage account stgacctaslinfraus2 (VHD do firewall)
│                            + VM aslfwus2 (firewall Mikrotik CHR, WAN + LAN)
└── rg-imagem-eastus2    -> reservado para golden image / Azure Compute
                             Gallery (sem recursos ainda)
```

A VNet tem 2 blocos de endereçamento (`address_space` é uma lista):

| Bloco da VNet | Cobre |
|---|---|
| `192.168.14.0/23` | `WANSubnet` |
| `10.172.28.0/22` | `LANSubnet` + `AVDSubnet` |

> O bloco `10.172.28.0/22` cobre de `10.172.28.0` a `10.172.31.255`, então
> tanto a `LANSubnet` (`10.172.29.0/24`) quanto a `AVDSubnet`
> (`10.172.30.0/24`) cabem dentro dele — não é mais necessário um terceiro
> bloco de endereçamento separado (o `10.172.32.0/24` usado antes foi
> removido do `vnet_address_space`).

| Subnet | CIDR | Uso pretendido | NSG |
|---|---|---|---|
| `WANSubnet` | `192.168.15.0/24` | Firewall Mikrotik (interface WAN, IP `.254`) | `nsg-wan-eastus2` |
| `LANSubnet` | `10.172.29.0/24` | Firewall Mikrotik (interface LAN, IP `.254`) + tráfego interno | `nsg-lan-eastus2` |
| `AVDSubnet` | `10.172.30.0/24` | Session hosts e storage FSLogix do projeto `avd-entra-iac` | `nsg-avd-eastus2` |

## Roteamento (`rt-lan-eastus2`)

Route table associada à `LANSubnet` e à `AVDSubnet`, com uma única rota:

| Rota | Destino | Next hop | Efeito |
|---|---|---|---|
| `default` | `0.0.0.0/0` | Virtual Appliance → `10.172.29.254` (interface LAN do firewall) | Todo tráfego sem rota mais específica das duas subnets passa pelo Mikrotik antes de sair |

> Como consequência, o tráfego de saída para internet dos session hosts do
> AVD (`avd-entra-iac`) e de qualquer host na `LANSubnet` passa a depender do
> firewall estar no ar e ter uma regra de NAT/roteamento configurada na
> interface WAN — sem isso, esse tráfego para de funcionar. Configure o NAT
> de saída (masquerade) no RouterOS antes de colocar cargas de produção
> nessas subnets.

## Firewall Mikrotik CHR (`aslfwus2`)

VM com 2 interfaces de rede, roteando tráfego entre a `WANSubnet` e a
`LANSubnet`:

| Interface | Subnet | IP privado | IP forwarding |
|---|---|---|---|
| WAN | `WANSubnet` | `192.168.15.254` (estático) | habilitado |
| LAN | `LANSubnet` | `10.172.29.254` (estático) | habilitado |

O `nsg-wan-eastus2` tem duas regras específicas para o firewall (a regra
genérica `DenyInternetInbound` foi removida propositalmente desta NSG — veja
abaixo):

| Regra | Prioridade | Efeito |
|---|---|---|
| `AllowAllInToFirewall` | 3990 | Permite qualquer origem com destino `192.168.15.254` (IP da interface WAN do firewall) |
| `DenyAllFromWanToLan` | 4000 | Bloqueia tráfego da `WANSubnet` (`192.168.14.0/23`) direto para as redes internas (`10.172.28.0/22`, que cobre LAN + AVD), forçando a passagem pelo firewall |

> A regra `DenyInternetInbound` (que bloqueava toda a tag `Internet`) foi
> removida do `nsg-wan-eastus2` de propósito: ela bloquearia qualquer
> tráfego vindo da internet pública antes mesmo de chegar na regra
> `AllowAllInToFirewall`, impedindo o Mikrotik de receber tráfego externo.
> O controle de acesso de borda agora é feito inteiramente pelo próprio
> RouterOS. As NSGs `nsg-lan-eastus2` e `nsg-avd-eastus2` mantêm o
> `DenyInternetInbound` normalmente.

### Por que o VHD não é gerenciado 100% pelo Terraform

O Terraform não baixa arquivos da internet nem converte formatos de disco.
Por isso o fluxo é dividido em duas partes:

1. **Terraform** cria o storage account (`stgacctaslinfraus2`), o container
   (`vhds`) e, quando `deploy_mikrotik_firewall = true`, o managed disk
   (`create_option = Import`, lendo o blob já enviado) + a VM.
2. **Workflow `mikrotik-vhd-prepare.yml`** (GitHub Actions, disparo manual)
   baixa o `.vhdx.zip` direto do site do Mikrotik, converte para VHD de
   tamanho fixo com `qemu-img` (não precisa de Windows/Hyper-V, roda num
   runner Linux comum) e sobe como page blob no container.

**Ordem obrigatória:**

1. `terraform apply` com `deploy_mikrotik_firewall = false` (padrão) — cria
   só o storage account/container.
2. Rodar manualmente o workflow **Mikrotik CHR - Preparar VHD** (aba Actions
   → Run workflow), informando a versão do CHR desejada.
3. Mudar `deploy_mikrotik_firewall` para `true` (via PR) e aplicar de novo —
   agora o managed disk consegue importar o blob e a VM é criada.

Se o Service Principal do GitHub Actions não tiver a role **Storage Blob
Data Contributor** no storage account, o passo 2 falha com 403. Conceda essa
role manualmente (Storage Account → Access Control (IAM) → Add role
assignment) ou preencha `mikrotik_upload_principal_object_id` com o Object
ID do Service Principal para o Terraform criar a role automaticamente.

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
`"name": "github-pr"` para habilitar o `plan` em Pull Requests. O workflow de
preparo do VHD (`mikrotik-vhd-prepare.yml`, disparado manualmente na branch
`main`) reaproveita a mesma credencial `github-main`.

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

Para o firewall, siga a ordem descrita na seção **Firewall Mikrotik CHR**
acima (apply do storage → workflow de preparo do VHD → `deploy_mikrotik_firewall = true` → novo apply).

## Próximos passos

- Módulo de golden image (Azure Compute Gallery + Image Definition) dentro
  de `rg-imagem-eastus2`, quando o processo de build da imagem for
  definido.
- Avaliar Private Endpoints / Azure Firewall na `WANSubnet` se a topologia
  evoluir para hub-and-spoke.
- Licenciamento do RouterOS (BYOL): comprar/aplicar a licença direto no
  Mikrotik depois que a VM subir — não é gerenciado pelo Terraform.
