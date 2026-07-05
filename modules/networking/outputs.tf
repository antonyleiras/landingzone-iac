output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "wan_subnet_id" {
  value = azurerm_subnet.wan.id
}

output "lan_subnet_id" {
  value = azurerm_subnet.lan.id
}

output "avd_subnet_id" {
  value = azurerm_subnet.avd.id
}

output "wan_nsg_id" {
  value = azurerm_network_security_group.wan.id
}

output "lan_nsg_id" {
  value = azurerm_network_security_group.lan.id
}

output "avd_nsg_id" {
  value = azurerm_network_security_group.avd.id
}

output "lan_route_table_id" {
  value = azurerm_route_table.lan.id
}
