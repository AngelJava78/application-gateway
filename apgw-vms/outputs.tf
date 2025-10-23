output "gateway_frontend_ip" {
  value = "http://${azurerm_public_ip.pip_agw.ip_address}"
}

output "admin_password" {
  value     = random_password.password.result
  sensitive = true
}
