resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# --- Subnets ---

resource "azurerm_subnet" "wan" {
  name                 = "WANSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.wan_subnet_prefix]
}

resource "azurerm_subnet" "lan" {
  name                 = "LANSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.lan_subnet_prefix]
}

resource "azurerm_subnet" "avd" {
  name                 = "AVDSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.avd_subnet_prefix]

  # Necessario para o Storage Account do FSLogix (projeto avd-entra-iac)
  # aceitar trafego apenas desta subnet.
  service_endpoints = ["Microsoft.Storage"]
}

# --- Network Security Groups (um por subnet, nomes explicitos) ---

resource "azurerm_network_security_group" "wan" {
  name                = var.nsg_wan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Permite trafego destinado a interface WAN do firewall Mikrotik
  # (aslfwus2, IP estatico 192.168.15.254). Prioridade menor que
  # DenyAllFromWanToLan para ser avaliada primeiro.
  #
  # OBS: a regra generica "DenyInternetInbound" (que existia aqui antes) foi
  # removida de proposito nesta NSG -- ela bloquearia todo trafego vindo da
  # tag "Internet" antes mesmo de chegar na regra abaixo, impedindo o
  # firewall de receber trafego da internet publica. O controle de acesso
  # de borda agora fica inteiramente a cargo do proprio RouterOS.
  security_rule {
    name                       = "AllowAllInToFirewall"
    priority                   = 3990
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.15.254"
  }

  # Bloqueia trafego vindo da WANSubnet com destino as redes internas
  # (LANSubnet + AVDSubnet), forcando que toda comunicacao WAN -> interna
  # passe pelo firewall Mikrotik (que tem suas proprias regras de roteamento
  # dentro do RouterOS) em vez de trafegar direto pela rede do Azure.
  #
  # LANSubnet (10.172.29.0/24) e AVDSubnet (10.172.30.0/24) cabem as duas
  # dentro do bloco 10.172.28.0/22, entao um unico destination_address_prefix
  # ja cobre as duas subnets internas.
  security_rule {
    name                       = "DenyAllFromWanToLan"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.14.0/23"
    destination_address_prefix = "10.172.28.0/22"
  }
}

resource "azurerm_network_security_group" "lan" {
  name                = var.nsg_lan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "avd" {
  name                = var.nsg_avd_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Trafego de saida necessario para os session hosts (repo avd-entra-iac)
  # se registrarem no servico do Azure Virtual Desktop e no Microsoft Entra.
  security_rule {
    name                       = "AllowAVDServiceOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "WindowsVirtualDesktop"
  }

  security_rule {
    name                       = "AllowAzureADOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
  }

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# --- Associacoes subnet <-> NSG ---

resource "azurerm_subnet_network_security_group_association" "wan" {
  subnet_id                 = azurerm_subnet.wan.id
  network_security_group_id = azurerm_network_security_group.wan.id
}

resource "azurerm_subnet_network_security_group_association" "lan" {
  subnet_id                 = azurerm_subnet.lan.id
  network_security_group_id = azurerm_network_security_group.lan.id
}

resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}

# --- Route table (LANSubnet + AVDSubnet -> firewall Mikrotik) ---

resource "azurerm_route_table" "lan" {
  name                = var.route_table_lan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Rota default: todo trafego sem rota mais especifica (0.0.0.0/0) e
# encaminhado para a interface LAN do firewall Mikrotik, que decide o que
# fazer com ele (NAT de saida, inspecao, etc.) em vez de sair direto pelo
# roteamento padrao do Azure.
resource "azurerm_route" "default_via_firewall" {
  name                   = "default"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.lan.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_lan_private_ip
}

resource "azurerm_subnet_route_table_association" "lan" {
  subnet_id      = azurerm_subnet.lan.id
  route_table_id = azurerm_route_table.lan.id
}

resource "azurerm_subnet_route_table_association" "avd" {
  subnet_id      = azurerm_subnet.avd.id
  route_table_id = azurerm_route_table.lan.id
}
