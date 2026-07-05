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
  # DenyAllFromWanToLan e DenyInternetInbound para ser avaliada primeiro.
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
  # OBS: o range pedido originalmente (10.172.30.0/22) nao e um CIDR valido
  # (30 nao e multiplo de 4 para /22) e tambem nao cobre a AVDSubnet. Foi
  # substituido pelos dois blocos reais usados no address_space da VNet:
  # 10.172.28.0/22 (contem a LANSubnet) e 10.172.32.0/24 (AVDSubnet).
  security_rule {
    name                         = "DenyAllFromWanToLan"
    priority                     = 4000
    direction                    = "Inbound"
    access                       = "Deny"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "192.168.14.0/23"
    destination_address_prefixes = ["10.172.28.0/22", "10.172.32.0/24"]
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
