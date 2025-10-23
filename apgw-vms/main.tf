# Crea un grupo de recursos en Azure con nombre dinámico y etiquetas personalizadas.
resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = "rg-${var.project}-${var.environment}-${var.region}"
  tags     = var.tags
}

# Crea una red virtual (VNet) con un espacio de direcciones definido.
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.21.0.0/16"]
  tags                = var.tags
}

# Crea una subred para el frontend dentro de la VNet.
resource "azurerm_subnet" "front_subnet" {
  name                 = "snet-front-${var.project}-${var.environment}-${var.region}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.21.0.0/24"]
}

# Crea una subred para el backend dentro de la VNet.
resource "azurerm_subnet" "back_subnet" {
  name                 = "snet-back-${var.project}-${var.environment}-${var.region}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.21.1.0/24"]
}

resource "azurerm_public_ip" "pip_agw" {
  name                = "pip-agw-${var.project}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "main" {
  name                = "myAppGateway"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.front_subnet.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_agw.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
    priority                   = 1
  }
}

resource "azurerm_network_interface" "nic_vm_01" {
  name                = "nic-vm-${var.project}-${var.environment}-${var.region}-01"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "nic-ipconfig-01"
    subnet_id                     = azurerm_subnet.back_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_vm_02" {
  name                = "nic-vm-${var.project}-${var.environment}-${var.region}-02"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "nic-ipconfig-02"
    subnet_id                     = azurerm_subnet.back_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic_assoc_01" {
  network_interface_id    = azurerm_network_interface.nic_vm_01.id
  ip_configuration_name   = "nic-ipconfig-01"
  backend_address_pool_id = one(azurerm_application_gateway.main.backend_address_pool).id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic_assoc_02" {
  network_interface_id    = azurerm_network_interface.nic_vm_02.id
  ip_configuration_name   = "nic-ipconfig-02"
  backend_address_pool_id = one(azurerm_application_gateway.main.backend_address_pool).id
}

resource "random_password" "password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  numeric = true
}

resource "azurerm_windows_virtual_machine" "vm_01" {
  name                = "vm${var.project}${var.environment}${var.region}01"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.vmSize_01
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.nic_vm_01.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}


resource "azurerm_windows_virtual_machine" "vm_02" {
  name                = "vm${var.project}${var.environment}${var.region}02"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.vmSize_02
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.nic_vm_02.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_extensions_01" {
  name                 = "vm-${var.project}-${var.environment}-${var.region}-ext-01"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

}


resource "azurerm_virtual_machine_extension" "vm_extensions_02" {
  name                 = "vm-${var.project}-${var.environment}-${var.region}-ext-02"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_02.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

}
