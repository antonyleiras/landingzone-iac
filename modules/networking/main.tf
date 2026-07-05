resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
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

# --- Network Security Groups (um por subnet) ---

resource "azurerm_network_security_group" "wan" {
  name                = "nsg-${var.name_prefix}-wan"
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

resource "azurerm_network_security_group" "lan" {
  name                = "nsg-${var.name_prefix}-lan"
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
  name                = "nsg-${var.name_prefix}-avd"
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
