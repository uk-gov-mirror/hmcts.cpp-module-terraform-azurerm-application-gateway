resource "random_id" "prefix" {
  byte_length = 4
}
resource "azurerm_resource_group" "test_rg" {
  name     = "${var.resource_group_name}-${random_id.prefix.hex}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "appgw_test_vn" {
  name                = "${var.appgw_vnet_name}-${random_id.prefix.hex}"
  address_space       = var.appgw_vnet_cidr
  location            = var.location
  resource_group_name = azurerm_resource_group.test_rg.name
  tags                = var.tags
}

resource "azurerm_virtual_network" "backend_test_vn" {
  name                = "${var.backend_vnet_name}-${random_id.prefix.hex}"
  address_space       = var.backend_vnet_cidr
  location            = var.location
  resource_group_name = azurerm_resource_group.test_rg.name
  tags                = var.tags
}

resource "azurerm_virtual_network_peering" "appgw_to_dmz" {
  name                      = "appgwtodmz2"
  resource_group_name       = azurerm_resource_group.test_rg.name
  virtual_network_name      = azurerm_virtual_network.appgw_test_vn.name
  remote_virtual_network_id = azurerm_virtual_network.backend_test_vn.id
}

resource "azurerm_virtual_network_peering" "backend_tp_appgw" {
  name                      = "backendtoappgw"
  resource_group_name       = azurerm_resource_group.test_rg.name
  virtual_network_name      = azurerm_virtual_network.backend_test_vn.name
  remote_virtual_network_id = azurerm_virtual_network.appgw_test_vn.id
}

module "test_appgw_subnet" {
  source                                                = "git::https://github.com/hmcts/cpp-module-terraform-azurerm-subnet.git?ref=main"
  subnet_name                                           = "${var.appgw_subnet_name}-${random_id.prefix.hex}"
  core_resource_group_name                              = azurerm_resource_group.test_rg.name
  virtual_network_name                                  = azurerm_virtual_network.appgw_test_vn.name
  subnet_address_prefixes                               = var.appgw_subnet_cidr
  subnet_enforce_private_link_endpoint_network_policies = false
  # service_endpoints                                     = ["Microsoft.KeyVault"] # Removed Key Vault service endpoint
}

module "test_backend_subnet" {
  source                                                = "git::https://github.com/hmcts/cpp-module-terraform-azurerm-subnet.git?ref=main"
  subnet_name                                           = "${var.backend_subnet_name}-${random_id.prefix.hex}"
  core_resource_group_name                              = azurerm_resource_group.test_rg.name
  virtual_network_name                                  = azurerm_virtual_network.backend_test_vn.name
  subnet_address_prefixes                               = var.backend_subnet_cidr
  subnet_enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_public_ip" "test_pip" {
  name                = "${var.name}-pip-${random_id.prefix.hex}"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_web_application_firewall_policy" "test_waf_policy" {
  name                = "${var.name}-tf-test-wafpolicy-${random_id.prefix.hex}"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 2000
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }

  custom_rules {
    name      = "JiraException"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }

      operator           = "Regex"
      negation_condition = false
      match_values       = ["\\/jira\\/(?:[^login\\.jsp\\W]).*"]
    }

    action = "Allow"
  }

  custom_rules {
    name      = "test"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }

      operator           = "Regex"
      negation_condition = false
      match_values       = ["\\/test.*"]
    }

    action = "Allow"
  }
  tags = var.tags
}

resource "azurerm_user_assigned_identity" "app-gw-identity" {
  location            = var.location
  name                = "${lower(var.name)}-identity-${random_id.prefix.hex}"
  resource_group_name = azurerm_resource_group.test_rg.name
}

module "appgw_terratest" {
  source              = "../../"
  name                = "${var.name}-${random_id.prefix.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.test_rg.name
  subnet_id           = module.test_appgw_subnet.id
  frontend_public_ip_address = {
    id         = azurerm_public_ip.test_pip.id
    ip_address = azurerm_public_ip.test_pip.ip_address
  }
  sku                       = var.sku
  autoscale_configuration   = var.autoscale_configuration
  frontend_port_settings    = var.frontend_port_settings
  backend_address_pools     = var.backend_address_pools
  backend_http_settings     = var.backend_http_settings
  http_listeners            = var.http_listeners
  request_routing_rules     = var.request_routing_rules
  ssl_certificates          = [] # Remove SSL certificates that depend on Key Vault
  ssl_policy                = var.ssl_policy
  health_probes             = var.health_probes
  url_path_maps             = var.url_path_maps
  firewall_policy_id        = azurerm_web_application_firewall_policy.test_waf_policy.id
  user_assigned_identity_id = azurerm_user_assigned_identity.app-gw-identity.id
  tags                      = var.tags

  # Remove Key Vault dependencies
  # depends_on = [
  #   azurerm_key_vault_certificate.self_signed_certificate,
  #   azurerm_key_vault.test,
  # ]
}

resource "random_password" "password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  numeric = true
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-${random_id.prefix.hex}-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.test_rg.name

  ip_configuration {
    name                          = "nic-ipconfig-${count.index + 1}"
    subnet_id                     = module.test_backend_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc01" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "nic-ipconfig-${count.index + 1}"
  backend_address_pool_id = module.appgw_terratest.backend_address_pool_id[0]
}

resource "azurerm_windows_virtual_machine" "vm" {
  count               = 2
  name                = "tf-${random_id.prefix.hex}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
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
  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "vm-extensions" {
  count                = 2
  name                 = "tf-${random_id.prefix.hex}-${count.index + 1}-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

  tags = var.tags
}
