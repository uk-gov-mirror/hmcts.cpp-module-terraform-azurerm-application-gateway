resource "azurerm_application_gateway" "app_gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = var.enable_http2
  zones               = var.zones
  firewall_policy_id  = var.firewall_policy_id != null ? var.firewall_policy_id : null

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? ["enabled"] : []
    content {
      min_capacity = var.autoscale_configuration.min_capacity
      max_capacity = var.autoscale_configuration.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = var.subnet_id
  }

  dynamic "frontend_port" {
    for_each = var.frontend_port_settings
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }


  dynamic "frontend_ip_configuration" {
    for_each = var.create_appgw_pip ? ["enabled"] : []
    content {
      name                 = local.frontend_ip_configuration_name
      public_ip_address_id = var.create_appgw_pip ? var.frontend_public_ip_address.id : null
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.appgw_private ? ["enabled"] : []
    content {
      name                            = local.frontend_priv_ip_configuration_name
      private_ip_address_allocation   = var.appgw_private_ip != null ? "Static" : null
      private_ip_address              = var.appgw_private ? var.appgw_private_ip : null
      subnet_id                       = var.appgw_private ? var.subnet_id : null
      private_link_configuration_name = var.privatelink != null ? var.privatelink.name : null
    }
  }

  #----------------------------------------------------------
  # Backend Address Pool Configuration (Required)
  #----------------------------------------------------------

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  #----------------------------------------------------------
  # Backend HTTP Settings (Required)
  #----------------------------------------------------------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    iterator = backend_http_settings
    content {
      name     = backend_http_settings.value.name
      port     = backend_http_settings.value.port
      protocol = backend_http_settings.value.protocol

      path       = backend_http_settings.value.path
      probe_name = backend_http_settings.value.probe_name

      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate != null ? ["enabled"] : []
        content {
          name = backend_http_settings.value.authentication_certificate
        }
      }

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining_timeout_sec != null ? ["enabled"] : []
        content {
          enabled           = true
          drain_timeout_sec = backend_http_settings.value.connection_draining_timeout_sec
        }
      }
    }
  }

  #----------------------------------------------------------
  # HTTP Listener Configuration (Required)
  #----------------------------------------------------------
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = coalesce(http_listener.value.frontend_ip_configuration_name, var.appgw_private ? local.frontend_priv_ip_configuration_name : local.frontend_ip_configuration_name)
      frontend_port_name             = http_listener.value.frontend_port_name
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      protocol                       = http_listener.value.protocol
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      ssl_profile_name               = http_listener.value.ssl_profile_name
      firewall_policy_id             = http_listener.value.firewall_policy_id
      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration
        iterator = err_conf
        content {
          status_code           = err_conf.value.status_code
          custom_error_page_url = err_conf.value.custom_error_page_url
        }
      }
    }
  }
  #----------------------------------------------------------
  # Request routing rules Configuration (Required)
  #----------------------------------------------------------
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name      = request_routing_rule.value.name
      rule_type = request_routing_rule.value.rule_type

      http_listener_name          = coalesce(request_routing_rule.value.http_listener_name, request_routing_rule.value.name)
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
      priority                    = request_routing_rule.value.priority
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_set
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules
        iterator = rule
        content {
          name          = rule.value.name
          rule_sequence = rule.value.rule_sequence

          dynamic "condition" {
            for_each = rule.value.conditions
            iterator = cond
            content {
              variable    = cond.value.variable
              pattern     = cond.value.pattern
              ignore_case = cond.value.ignore_case
              negate      = cond.value.negate
            }
          }

          dynamic "response_header_configuration" {
            for_each = rule.value.response_header_configurations
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "request_header_configuration" {
            for_each = rule.value.request_header_configurations
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "url" {
            for_each = rule.value.url_reroute != null ? ["enabled"] : []
            content {
              path         = rule.value.url_reroute.path
              query_string = rule.value.url_reroute.query_string
              components   = rule.value.url_reroute.components
              reroute      = rule.value.url_reroute.reroute
            }
          }
        }
      }
    }
  }

  #---------------------------------------------------------------
  # Identity block Configuration (Optional)
  # A list with a single user managed identity id to be assigned
  #---------------------------------------------------------------
  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null ? ["enabled"] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  #----------------------------------------------------------
  # Authentication SSL Certificate Configuration (Optional)
  #----------------------------------------------------------
  dynamic "authentication_certificate" {
    for_each = var.authentication_certificates
    content {
      name = authentication_certificate.value.name
      data = filebase64(authentication_certificate.value.data)
    }
  }

  #----------------------------------------------------------
  # Trusted Root SSL Certificate Configuration (Optional)
  #----------------------------------------------------------
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name = trusted_root_certificate.value.name
      data = base64encode(trusted_root_certificate.value.data)
    }
  }

  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  # SSL Policy for Application Gateway (Optional)
  # Application Gateway has three predefined security policies to get the appropriate level of security
  # AppGwSslPolicy20150501 - MinProtocolVersion(TLSv1_0), AppGwSslPolicy20170401 - MinProtocolVersion(TLSv1_1), AppGwSslPolicy20170401S - MinProtocolVersion(TLSv1_2)
  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  dynamic "ssl_policy" {
    for_each = var.ssl_policy == null ? [] : ["enabled"]
    content {
      disabled_protocols   = var.ssl_policy.disabled_protocols
      policy_type          = var.ssl_policy.policy_type
      policy_name          = var.ssl_policy.policy_type == "Predefined" ? var.ssl_policy.policy_name : null
      cipher_suites        = var.ssl_policy.policy_type == "Custom" ? var.ssl_policy.cipher_suites : null
      min_protocol_version = var.ssl_policy.policy_type == "Custom" ? var.ssl_policy.min_protocol_version : null
    }
  }

  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  # SSL profile for Application Gateway (Optional)
  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  dynamic "ssl_profile" {
    for_each = var.ssl_profile == null ? [] : ["enabled"]

    content {
      name                             = var.ssl_profile.name
      trusted_client_certificate_names = var.ssl_profile.trusted_client_certificate_names
      verify_client_cert_issuer_dn     = var.ssl_profile.verify_client_cert_issuer_dn
      dynamic "ssl_policy" {
        for_each = var.ssl_profile.ssl_policy == null ? [] : ["enabled"]
        content {
          disabled_protocols   = var.ssl_profile.ssl_policy.disabled_protocols
          policy_type          = var.ssl_profile.ssl_policy.policy_type
          policy_name          = var.ssl_profile.ssl_policy.policy_type == "Predefined" ? var.ssl_profile.ssl_policy.policy_name : null
          cipher_suites        = var.ssl_profile.ssl_policy.policy_type == "Custom" ? var.ssl_profile.ssl_policy.cipher_suites : null
          min_protocol_version = var.ssl_profile.ssl_policy.policy_type == "Custom" ? var.ssl_profile.ssl_policy.min_protocol_version : null
        }
      }
    }
  }

  #----------------------------------------------------------
  # SSL Certificate (.pfx) Configuration (Optional)
  #----------------------------------------------------------
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? filebase64(ssl_certificate.value.data) : null
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
    }
  }

  #----------------------------------------------------------
  # Health Probe (Optional)
  #----------------------------------------------------------
  dynamic "probe" {
    for_each = var.health_probes
    content {
      name = probe.value.name

      host     = probe.value.host
      port     = probe.value.port
      interval = probe.value.interval

      path     = probe.value.path
      protocol = probe.value.protocol
      timeout  = probe.value.timeout

      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      minimum_servers                           = probe.value.minimum_servers
      match {
        body        = probe.value.match.body
        status_code = probe.value.match.status_code
      }
    }
  }

  #----------------------------------------------------------
  # URL Path Mappings (Optional)
  #----------------------------------------------------------
  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name
      default_backend_http_settings_name  = url_path_map.value.default_redirect_configuration_name == null ? coalesce(url_path_map.value.default_backend_http_settings_name, url_path_map.value.default_backend_address_pool_name) : null
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          backend_address_pool_name  = coalesce(path_rule.value.backend_address_pool_name, path_rule.value.name)
          backend_http_settings_name = coalesce(path_rule.value.backend_http_settings_name, path_rule.value.name)
          rewrite_rule_set_name      = path_rule.value.rewrite_rule_set_name
          paths                      = path_rule.value.paths
        }
      }
    }
  }

  # #----------------------------------------------------------
  # # Redirect Configuration (Optional)
  # #----------------------------------------------------------
  dynamic "redirect_configuration" {
    for_each = var.redirect_configuration
    iterator = redirect
    content {
      name                 = redirect.value.name
      redirect_type        = redirect.value.redirect_type
      target_listener_name = redirect.value.target_listener_name
      target_url           = redirect.value.target_url
      include_path         = redirect.value.include_path
      include_query_string = redirect.value.include_query_string
    }
  }

  # #----------------------------------------------------------
  # # Custom error configuration (Optional)
  # #----------------------------------------------------------
  dynamic "custom_error_configuration" {
    for_each = var.custom_error_configuration
    iterator = err_conf
    content {
      status_code           = err_conf.value.status_code
      custom_error_page_url = err_conf.value.custom_error_page_url
    }
  }

  #----------------------------------------------------------
  # Web application Firewall (WAF) configuration (Optional)
  # Tier to be either “WAF” or “WAF V2”
  #----------------------------------------------------------
  dynamic "waf_configuration" {
    for_each = var.sku == "WAF_v2" && var.waf_configuration != null ? [var.waf_configuration] : []
    content {
      enabled                  = waf_configuration.value.enabled
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      firewall_mode            = waf_configuration.value.firewall_mode
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
      request_body_check       = waf_configuration.value.request_body_check
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version

      dynamic "disabled_rule_group" {
        for_each = local.disabled_rule_group_settings != null ? local.disabled_rule_group_settings : []
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = disabled_rule_group.value.rules
        }
      }

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion != null ? waf_configuration.value.exclusion : []
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
        }
      }
    }
  }

  dynamic "private_link_configuration" {
    for_each = var.privatelink != null ? [var.privatelink] : []
    content {
      name = private_link_configuration.value.name

      ip_configuration {
        name                          = private_link_configuration.value.ip_configuration_name
        subnet_id                     = private_link_configuration.value.subnet_id
        private_ip_address_allocation = lookup(private_link_configuration.value, "private_ip_address", null) != null ? "Static" : "Dynamic"
        private_ip_address            = lookup(private_link_configuration.value, "private_ip_address", null)
        primary                       = true
      }
    }
  }

  tags = var.tags
}

#---------------------------------------------------------------
# azurerm monitoring diagnostics (Optional)
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
#---------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  for_each = { for ds in var.diagnostic_settings : ds.name => ds }

  name                           = each.value.name
  target_resource_id             = azurerm_application_gateway.app_gateway.id
  storage_account_id             = each.value.storage_account_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  eventhub_name                  = each.value.eventhub_name
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id

  dynamic "enabled_log" {
    for_each = each.value.enabled_logs != null ? each.value.enabled_logs : []
    content {
      category = try(enabled_log.value.category, null)
    }
  }
}
