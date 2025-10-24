variable "cert_password" {
  description = "Password for the PFX certificate"
  type        = string
  sensitive   = true
}

resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = "rg-${var.project}-${var.environment}-${var.region}"
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.21.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "agw_subnet" {
  name                 = "snet-agw-${var.project}-${var.environment}-${var.region}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_public_ip" "pip_agw" {
  name                = "pip-agw-${var.project}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-${var.project}-${var.environment}-${var.region}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_web_app" "web_app" {
  name                = "webapp-${var.project}-${var.environment}-${var.region}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "14.17.0"
  }
}

resource "azurerm_application_gateway" "main" {
  name                = "agw-${var.project}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.agw_subnet.id
  }

  frontend_port {
    name = "frontendPort443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontendIP"
    public_ip_address_id = azurerm_public_ip.pip_agw.id
  }

  ssl_certificate {
    name     = "sslCert"
    data     = filebase64("certificado.pfx")
    password = var.cert_password
  }

  backend_address_pool {
    name  = "backendPool"
    fqdns = [azurerm_windows_web_app.web_app.default_hostname]
  }

  backend_http_settings {
    name                                = "httpSettings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    host_name                           = azurerm_windows_web_app.web_app.default_hostname
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "frontendIP"
    frontend_port_name             = "frontendPort443"
    protocol                       = "Https"
    ssl_certificate_name           = "sslCert"
    host_name                      = "miapp.midominio.com"
  }

  request_routing_rule {
    name                       = "routingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpsListener"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "httpSettings"
    priority                   = 1
  }
}