output "appgw_id" {
  description = "The ID of the Application Gateway."
  value       = azurerm_application_gateway.app_gateway.id
}

output "appgw_name" {
  description = "The name of the Application Gateway."
  value       = azurerm_application_gateway.app_gateway.name
}

output "backend_address_pool_id" {
  description = "The backend address pool id"
  value       = azurerm_application_gateway.app_gateway.backend_address_pool.*.id
}
