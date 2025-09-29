output "appgw_id" {
  description = "The ID of the Application Gateway."
  value       = module.appgw_terratest.appgw_id
}

output "appgw_name" {
  description = "The name of the Application Gateway."
  value       = module.appgw_terratest.appgw_name
}

output "backend_subnet_id" {
  description = "The backend subnet id"
  value       = module.test_backend_subnet.id
}

output "backend_address_pool_id" {
  description = "The backend address pool id"
  value       = module.appgw_terratest.backend_address_pool_id
}
