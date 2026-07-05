# Storage account que recebe o VHD fixo do Mikrotik CHR (upload feito pelo
# workflow .github/workflows/mikrotik-vhd-prepare.yml, fora do Terraform,
# porque envolve download + conversao vhdx->vhd que nao sao acoes do
# provider azurerm).
resource "azurerm_storage_account" "vhds" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_storage_container" "vhds" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.vhds.name
  container_access_type = "private"
}

# RBAC de dados opcional, para o Service Principal do GitHub Actions poder
# subir o blob via "az storage blob upload --auth-mode login".
resource "azurerm_role_assignment" "upload_rbac" {
  count                = var.upload_principal_object_id != null ? 1 : 0
  scope                = azurerm_storage_account.vhds.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.upload_principal_object_id
}

# --- Managed disk importado do VHD (so depois que o blob ja existe) ---

resource "azurerm_managed_disk" "mikrotik_os" {
  count                = var.deploy_vm ? 1 : 0
  name                 = "osdisk-${var.vm_name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  os_type              = "Linux"
  create_option        = "Import"
  storage_account_id   = azurerm_storage_account.vhds.id
  source_uri           = "${azurerm_storage_account.vhds.primary_blob_endpoint}${var.container_name}/${var.vhd_blob_name}"
  storage_account_type = var.disk_type
  disk_size_gb         = var.disk_size_gb

  tags = var.tags
}

resource "azurerm_public_ip" "wan" {
  count               = var.deploy_vm && var.create_wan_public_ip ? 1 : 0
  name                = "pip-${var.vm_name}-wan"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Interface WAN. IP forwarding habilitado nas duas interfaces porque o
# Mikrotik precisa rotear pacotes entre a WANSubnet e a LANSubnet (sem isso
# o Azure descarta pacotes cujo IP de origem/destino nao e o da propria NIC).
resource "azurerm_network_interface" "wan" {
  count                = var.deploy_vm ? 1 : 0
  name                 = "nic-${var.vm_name}-wan"
  resource_group_name  = var.resource_group_name
  location             = var.location
  enable_ip_forwarding = true
  tags                 = var.tags

  ip_configuration {
    name                          = "wan"
    subnet_id                     = var.wan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.wan_private_ip
    public_ip_address_id          = var.create_wan_public_ip ? azurerm_public_ip.wan[0].id : null
  }
}

resource "azurerm_network_interface" "lan" {
  count                = var.deploy_vm ? 1 : 0
  name                 = "nic-${var.vm_name}-lan"
  resource_group_name  = var.resource_group_name
  location             = var.location
  enable_ip_forwarding = true
  tags                 = var.tags

  ip_configuration {
    name                          = "lan"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_private_ip
  }
}

resource "azurerm_virtual_machine" "mikrotik" {
  count                         = var.deploy_vm ? 1 : 0
  name                          = var.vm_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  vm_size                       = var.vm_size
  network_interface_ids         = [azurerm_network_interface.wan[0].id, azurerm_network_interface.lan[0].id]
  primary_network_interface_id  = azurerm_network_interface.wan[0].id
  delete_os_disk_on_termination = false

  storage_os_disk {
    name            = azurerm_managed_disk.mikrotik_os[0].name
    create_option   = "Attach"
    os_type         = "Linux"
    managed_disk_id = azurerm_managed_disk.mikrotik_os[0].id
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.vhds.primary_blob_endpoint
  }

  tags = var.tags
}
