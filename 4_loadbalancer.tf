# create public ip for load balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "public-ip-vmss-demo"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

# create load balancer
resource "azurerm_lb" "lb" {
  name                = "lb-vmss-demo"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip-vmss-demo"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# create tcp probe for https 443
resource "azurerm_lb_probe" "tcp_probe_443" {
  name                = "tcp-probe-443-vmss-demo"
    loadbalancer_id     = azurerm_lb.lb.id
    protocol            = "Tcp"
    port                = 443
    }

# create tcp probe for http 80
resource "azurerm_lb_probe" "tcp_probe_80" {
  name                = "tcp-probe-80-vmss-demo"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
}

# create http probe for /health
resource "azurerm_lb_probe" "http_probe_health" {
  name                = "http-probe-health-vmss-demo"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
}

# create backend address pool
resource "azurerm_lb_backend_address_pool" "backend_address_pool_vmss" {
  name                = "backend-address-pool-vms-vmss-demo"
  loadbalancer_id     = azurerm_lb.lb.id
}

# create load balancer rule for https 443, using http probe
resource "azurerm_lb_rule" "lb_rule_https" {
  name                = "lb-rule-https-vmss-demo"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  frontend_port       = 443
  backend_port        = 443
  probe_id = azurerm_lb_probe.http_probe_health.id
  disable_outbound_snat = true
  frontend_ip_configuration_name = "frontend-ip-vmss-demo"
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.backend_address_pool_vmss.id ]
}

# create load balancer rule for http 80, using http probe
resource "azurerm_lb_rule" "lb_rule_http" {
  name                = "lb-rule-http-vmss-demo"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  frontend_port       = 80
  backend_port        = 80   
  probe_id = azurerm_lb_probe.http_probe_health.id
  frontend_ip_configuration_name = "frontend-ip-vmss-demo"
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.backend_address_pool_vmss.id ]
}

# output lb public ip
output "lb_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}
