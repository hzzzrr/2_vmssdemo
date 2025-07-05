# 创建vnet, 每个region 用一个vnet，使用region_settings 中的address_space,
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-vmss-demo"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# 创建vm subnet
resource "azurerm_subnet" "vm_subnet" {
  name                          = "vm-subnet-vmss-demo"
  virtual_network_name          = azurerm_virtual_network.vnet.name
  resource_group_name           = azurerm_resource_group.rg.name
  address_prefixes              = ["10.0.0.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

# create nsg to allow 22,443,80
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-vmss-demo"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
}

# create nsg rule to allow http/https
resource "azurerm_network_security_rule" "nsg_rule_http_https" {
  name                        = "nsg-rule-vmss-demo-http-https"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "80","5566"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# create nsg rule to allow http/https
resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = "nsg-rule-vmss-demo-ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# associate nsg to vm subnet
resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}




