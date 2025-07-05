# 在每个region中，创建一个resource group，名字中使用region name作为后缀。
resource "azurerm_resource_group" "rg" {
  name                = "2-vmss-demo"
  location            = var.primary_region
}
