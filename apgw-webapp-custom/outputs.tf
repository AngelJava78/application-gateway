output "gateway_frontend_ip" {
  value = "http://${azurerm_public_ip.pip_agw.ip_address}"
}

output "hostname" {
  value = azurerm_windows_web_app.web_app.default_hostname
}