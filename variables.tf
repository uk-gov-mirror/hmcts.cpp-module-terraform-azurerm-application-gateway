variable "name" {
  type        = string
  description = "The name of the Application Gateway."
}

variable "location" {
  type        = string
  description = "The location/region where the Application Gateway is created."
  default     = "uksouth"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Application Gateway."
}

variable "subnet_id" {
  description = "Subnet ID for attaching the Application Gateway."
  type        = string
  default     = ""
}

variable "frontend_public_ip_address" {
  description = "Frontend public IP address"
  type        = map(string)
  default     = {}
}

variable "appgw_private" {
  description = "Boolean variable to create a private Application Gateway. When `true`, the default http listener will listen on private IP instead of the public IP."
  type        = bool
  default     = false
}

variable "appgw_private_ip" {
  description = "Private IP for Application Gateway. Used when variable `appgw_private` is set to `true`."
  type        = string
  default     = null
}

variable "frontend_port_settings" {
  description = "Frontend port settings. Each port setting contains the name and the port for the frontend port."
  type = list(object({
    name = string
    port = number
  }))
}

variable "enable_http2" {
  description = "Is HTTP2 enabled on the application gateway resource?"
  type        = bool
  default     = true
}

variable "zones" {
  description = "A collection of availability zones to spread the Application Gateway over."
  type        = list(string)
  default     = [] #["1", "2", "3"]
}

variable "firewall_policy_id" {
  description = "The ID of the Web Application Firewall Policy which can be associated with app gateway"
  default     = null
}

variable "sku" {
  description = "The sku pricing model of v1 and v2"
  type = object({
    name     = string
    tier     = string
    capacity = optional(number)
  })
}

variable "autoscale_configuration" {
  description = "Map containing autoscaling parameters. Must contain at least min_capacity"
  type = object({
    min_capacity = number
    max_capacity = optional(number, 5)
  })
  default = null
}

variable "private_ip_address" {
  description = "Private IP Address to assign to the Load Balancer."
  default     = null
}

variable "backend_address_pools" {
  description = "List of backend address pools"
  type = list(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "List of objects including backend http settings configurations."
  type = list(object({
    name     = string
    port     = optional(number, 443)
    protocol = optional(string, "Https")

    path       = optional(string)
    probe_name = optional(string)

    cookie_based_affinity               = optional(string, "Disabled")
    affinity_cookie_name                = optional(string, "ApplicationGatewayAffinity")
    request_timeout                     = optional(number, 20)
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool, true)
    trusted_root_certificate_names      = optional(list(string), [])
    authentication_certificate          = optional(string)

    connection_draining_timeout_sec = optional(number)
  }))
}

variable "http_listeners" {
  description = "List of objects with HTTP listeners configurations and custom error configurations."
  type = list(object({
    name = string

    frontend_ip_configuration_name = optional(string)
    frontend_port_name             = optional(string)
    host_name                      = optional(string)
    host_names                     = optional(list(string))
    protocol                       = optional(string, "Https")
    require_sni                    = optional(bool, false)
    ssl_certificate_name           = optional(string)
    ssl_profile_name               = optional(string)
    firewall_policy_id             = optional(string)

    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })), [])
  }))
}

variable "request_routing_rules" {
  description = "List of objects with request routing rules configurations. Priority is required for stability."
  type = list(object({
    name                        = string
    rule_type                   = optional(string, "Basic")
    http_listener_name          = optional(string)
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    url_path_map_name           = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
    priority                    = number # Required
  }))
}

variable "identity_ids" {
  description = "Specifies a list with a single user managed identity id to be assigned to the Application Gateway"
  default     = null
}

variable "authentication_certificates" {
  description = "Authentication certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "trusted_root_certificates" {
  description = "Trusted root certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "ssl_policy" {
  description = "Application Gateway SSL configuration. The list of available policies can be found here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#disabled_protocols"
  type = object({
    disabled_protocols   = optional(list(string), [])
    policy_type          = optional(string, "Predefined")
    policy_name          = optional(string, "AppGwSslPolicy20170401S")
    cipher_suites        = optional(list(string), [])
    min_protocol_version = optional(string, "TLSv1_2")
  })
  default = null
}

variable "ssl_profile" {
  description = "Application Gateway SSL profile. Default profile is used when this variable is set to null. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#name"
  type = object({
    name                             = string
    trusted_client_certificate_names = optional(list(string), [])
    verify_client_cert_issuer_dn     = optional(bool, false)
    ssl_policy = optional(object({
      disabled_protocols   = optional(list(string), [])
      policy_type          = optional(string, "Predefined")
      policy_name          = optional(string, "AppGwSslPolicy20170401S")
      cipher_suites        = optional(list(string), [])
      min_protocol_version = optional(string, "TLSv1_2")
    }))
  })
  default = null
}

variable "ssl_certificates" {
  description = "List of SSL certificates data for Application gateway"
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = []
}

variable "health_probes" {
  description = "List of objects with probes configurations."
  type = list(object({
    name     = string
    host     = optional(string)
    port     = optional(number, null)
    interval = optional(number, 30)
    path     = optional(string, "/")
    protocol = optional(string, "Https")
    timeout  = optional(number, 30)

    unhealthy_threshold                       = optional(number, 3)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    minimum_servers                           = optional(number, 0)

    match = optional(object({
      body        = optional(string, "")
      status_code = optional(list(string), ["200-399"])
    }), {})
  }))
  default = []
}

variable "url_path_maps" {
  description = "List of objects with URL path map configurations."
  type = list(object({
    name = string

    default_backend_address_pool_name   = optional(string)
    default_redirect_configuration_name = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_rewrite_rule_set_name       = optional(string)

    path_rules = list(object({
      name = string

      backend_address_pool_name  = optional(string)
      backend_http_settings_name = optional(string)
      rewrite_rule_set_name      = optional(string)

      paths = optional(list(string), [])
    }))
  }))
  default = []
}

variable "redirect_configuration" {
  description = "List of objects with redirect configurations."
  type = list(object({
    name = string

    redirect_type        = optional(string, "Permanent")
    target_listener_name = optional(string)
    target_url           = optional(string)

    include_path         = optional(bool, true)
    include_query_string = optional(bool, true)
  }))
  default = []
}

variable "custom_error_configuration" {
  description = "List of objects with global level custom error configurations."
  type = list(object({
    status_code           = string
    custom_error_page_url = string
  }))
  default = []
}

variable "rewrite_rule_set" {
  description = "List of rewrite rule set objects with rewrite rules."
  type = list(object({
    name = string
    rewrite_rules = list(object({
      name          = string
      rule_sequence = string

      conditions = optional(list(object({
        variable    = string
        pattern     = string
        ignore_case = optional(bool, false)
        negate      = optional(bool, false)
      })), [])

      response_header_configurations = optional(list(object({
        header_name  = string
        header_value = string
      })), [])

      request_header_configurations = optional(list(object({
        header_name  = string
        header_value = string
      })), [])

      url_reroute = optional(object({
        path         = optional(string)
        query_string = optional(string)
        components   = optional(string)
        reroute      = optional(bool)
      }))
    }))
  }))
  default = []
}

variable "disable_waf_rules_for_dev_portal" {
  description = "Whether to disable some WAF rules if the APIM developer portal is hosted behind this Application Gateway. See locals.tf for the documentation link."
  type        = bool
  default     = false
}

variable "waf_configuration" {
  description = <<EOD
WAF configuration object (only available with WAF_v2 SKU) with following attributes:
```
- enabled:                  Boolean to enable WAF.
- file_upload_limit_mb:     The File Upload Limit in MB. Accepted values are in the range 1MB to 500MB.
- firewall_mode:            The Web Application Firewall Mode. Possible values are Detection and Prevention.
- max_request_body_size_kb: The Maximum Request Body Size in KB. Accepted values are in the range 1KB to 128KB.
- request_body_check:       Is Request Body Inspection enabled ?
- rule_set_type:            The Type of the Rule Set used for this Web Application Firewall.
- rule_set_version:         The Version of the Rule Set used for this Web Application Firewall. Possible values are 2.2.9, 3.0, and 3.1.
- disabled_rule_group:      The rule group where specific rules should be disabled. Accepted values can be found here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#rule_group_name
- exclusion:                WAF exclusion rules to exclude header, cookie or GET argument. More informations on: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#match_variable
```
EOD
  type = object({
    enabled                  = optional(bool, false)
    file_upload_limit_mb     = optional(number, 100)
    firewall_mode            = optional(string, "Prevention")
    max_request_body_size_kb = optional(number, 128)
    request_body_check       = optional(bool, true)
    rule_set_type            = optional(string, "OWASP")
    rule_set_version         = optional(string, 3.1)
    disabled_rule_group = optional(list(object({
      rule_group_name = string
      rules           = optional(list(string))
    })), [])
    exclusion = optional(list(object({
      match_variable          = string
      selector                = optional(string)
      selector_match_operator = optional(string)
    })), [])
  })
  default = {}
}

variable "user_assigned_identity_id" {
  description = "User assigned identity id assigned to this resource."
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
}

variable "diagnostic_settings" {
  type = list(object({
    name                           = string
    storage_account_id             = optional(string)
    log_analytics_workspace_id     = optional(string)
    log_analytics_destination_type = optional(string)
    eventhub_name                  = optional(string)
    eventhub_authorization_rule_id = optional(string)
    enabled_logs = optional(list(object({
      category       = optional(string)
    })))
  }))
  default = []
}

variable "create_appgw_pip" {
  type        = bool
  description = "Create a public IP for the Application Gateway."
  default     = true
}

variable "privatelink" {
  description = "Private Link config for Application Gateway (optional)"
  type = object({
    name                  = string
    ip_configuration_name = string
    subnet_id             = string
    private_ip_address    = optional(string)
  })
  default = null
}
