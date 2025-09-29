name                = "APPGW-TF-TEST-01"
resource_group_name = "RG-APPGW-TF-TEST-DMZ-01"
appgw_vnet_name     = "VN-APPGW-TF-TEST-DMZ-01"
appgw_vnet_cidr     = ["10.251.0.0/25"]
appgw_subnet_name   = "SN-APPGW-TF-TEST-DMZ-01"
appgw_subnet_cidr   = ["10.251.0.0/26"]
backend_vnet_name   = "VN-APPGW-TF-TEST-BCKEND-01"
backend_subnet_name = "SN-APPGW-TF-TEST-BCKEND-01"
backend_vnet_cidr   = ["10.251.0.128/25"]
backend_subnet_cidr = ["10.251.0.128/26"]
frontend_port_settings = [{
  name = "http-feport"
  port = 80
}]
sku = {
  name = "WAF_v2"
  tier = "WAF_v2"
}
autoscale_configuration = {
  min_capacity = 1
  max_capacity = 2
}
backend_address_pools = [{
  name = "tf-test-beap"
}]
health_probes = [{
  name                                      = "tf-test-probe"
  pick_host_name_from_backend_http_settings = true
  protocol                                  = "Http"
}]
backend_http_settings = [{
  name                  = "tf-test-be-htst"
  cookie_based_affinity = "Disabled"
  path                  = "/"
  port                  = 80
  protocol              = "Http"
  request_timeout       = 300
  probe_name            = "tf-test-probe"
}]
http_listeners = [{
  name               = "http-httplstn"
  frontend_port_name = "http-feport"
  protocol           = "Http"
  # ssl_certificate_name = "tf-test-sslcert" # Removed SSL certificate dependency
  require_sni = false
}]
request_routing_rules = [{
  name                       = "http-rqrt"
  rule_type                  = "Basic"
  http_listener_name         = "http-httplstn"
  backend_address_pool_name  = "tf-test-beap"
  backend_http_settings_name = "tf-test-be-htst"
  priority                   = 100
}]
url_path_maps = [{
  name                               = "tf-test-url-path-map"
  default_backend_http_settings_name = "tf-test-be-htst"
  default_backend_address_pool_name  = "tf-test-beap"
  path_rules = [
    {
      name                       = "tf-test-url-path-rule"
      backend_address_pool_name  = "tf-test-beap"
      backend_http_settings_name = "tf-test-be-htst"
      paths                      = ["/test/"]
    }
  ]
}]
tags = {
  environment         = "test"
  project             = "terratest"
  platform            = "nlv"
  business_area       = "Crime"
  data_classification = "Internal"
  type                = "appgw"
  owner               = "HMCTS-SP"
}
