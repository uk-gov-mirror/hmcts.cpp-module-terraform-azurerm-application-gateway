# Azure Application Gateway Terraform Module

This Terraform module creates an Azure Application Gateway with comprehensive configuration options including WAF, SSL, backend pools, listeners, routing rules, and diagnostics.

## Breaking Changes

### Priority Field Required

**IMPORTANT**: The `priority` field is now **required** for all request routing rules.

#### Migration Required

**Before Update:**
```hcl
request_routing_rules = [{
  name                       = "my-rule"
  rule_type                  = "Basic"
  http_listener_name         = "my-listener"
  backend_address_pool_name  = "my-backend"
  backend_http_settings_name = "my-settings"
  # priority was optional/auto-generated
}]
```

**After Update:**
```hcl
request_routing_rules = [{
  name                       = "my-rule"
  rule_type                  = "Basic"
  http_listener_name         = "my-listener"
  backend_address_pool_name  = "my-backend"
  backend_http_settings_name = "my-settings"
  priority                   = 100  # Now required
}]
```

Use priority values with gaps (e.g., 100, 200, 300) to allow for future insertions.

---

<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_gateway.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_monitor_diagnostic_setting.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_appgw_private"></a> [appgw\_private](#input\_appgw\_private) | Boolean variable to create a private Application Gateway. When `true`, the default http listener will listen on private IP instead of the public IP. | `bool` | `false` | no |
| <a name="input_appgw_private_ip"></a> [appgw\_private\_ip](#input\_appgw\_private\_ip) | Private IP for Application Gateway. Used when variable `appgw_private` is set to `true`. | `string` | `null` | no |
| <a name="input_authentication_certificates"></a> [authentication\_certificates](#input\_authentication\_certificates) | Authentication certificates to allow the backend with Azure Application Gateway | <pre>list(object({<br/>    name = string<br/>    data = string<br/>  }))</pre> | `[]` | no |
| <a name="input_autoscale_configuration"></a> [autoscale\_configuration](#input\_autoscale\_configuration) | Map containing autoscaling parameters. Must contain at least min\_capacity | <pre>object({<br/>    min_capacity = number<br/>    max_capacity = optional(number, 5)<br/>  })</pre> | `null` | no |
| <a name="input_backend_address_pools"></a> [backend\_address\_pools](#input\_backend\_address\_pools) | List of backend address pools | <pre>list(object({<br/>    name         = string<br/>    fqdns        = optional(list(string))<br/>    ip_addresses = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_backend_http_settings"></a> [backend\_http\_settings](#input\_backend\_http\_settings) | List of objects including backend http settings configurations. | <pre>list(object({<br/>    name     = string<br/>    port     = optional(number, 443)<br/>    protocol = optional(string, "Https")<br/><br/>    path       = optional(string)<br/>    probe_name = optional(string)<br/><br/>    cookie_based_affinity               = optional(string, "Disabled")<br/>    affinity_cookie_name                = optional(string, "ApplicationGatewayAffinity")<br/>    request_timeout                     = optional(number, 20)<br/>    host_name                           = optional(string)<br/>    pick_host_name_from_backend_address = optional(bool, true)<br/>    trusted_root_certificate_names      = optional(list(string), [])<br/>    authentication_certificate          = optional(string)<br/><br/>    connection_draining_timeout_sec = optional(number)<br/>  }))</pre> | n/a | yes |
| <a name="input_create_appgw_pip"></a> [create\_appgw\_pip](#input\_create\_appgw\_pip) | Create a public IP for the Application Gateway. | `bool` | `true` | no |
| <a name="input_custom_error_configuration"></a> [custom\_error\_configuration](#input\_custom\_error\_configuration) | List of objects with global level custom error configurations. | <pre>list(object({<br/>    status_code           = string<br/>    custom_error_page_url = string<br/>  }))</pre> | `[]` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | n/a | <pre>list(object({<br/>    name                           = string<br/>    storage_account_id             = optional(string)<br/>    log_analytics_workspace_id     = optional(string)<br/>    log_analytics_destination_type = optional(string)<br/>    eventhub_name                  = optional(string)<br/>    eventhub_authorization_rule_id = optional(string)<br/>    enabled_logs = optional(list(object({<br/>      category = optional(string)<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_disable_waf_rules_for_dev_portal"></a> [disable\_waf\_rules\_for\_dev\_portal](#input\_disable\_waf\_rules\_for\_dev\_portal) | Whether to disable some WAF rules if the APIM developer portal is hosted behind this Application Gateway. See locals.tf for the documentation link. | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Is HTTP2 enabled on the application gateway resource? | `bool` | `true` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | The ID of the Web Application Firewall Policy which can be associated with app gateway | `any` | `null` | no |
| <a name="input_frontend_port_settings"></a> [frontend\_port\_settings](#input\_frontend\_port\_settings) | Frontend port settings. Each port setting contains the name and the port for the frontend port. | <pre>list(object({<br/>    name = string<br/>    port = number<br/>  }))</pre> | n/a | yes |
| <a name="input_frontend_public_ip_address"></a> [frontend\_public\_ip\_address](#input\_frontend\_public\_ip\_address) | Frontend public IP address | `map(string)` | `{}` | no |
| <a name="input_health_probes"></a> [health\_probes](#input\_health\_probes) | List of objects with probes configurations. | <pre>list(object({<br/>    name     = string<br/>    host     = optional(string)<br/>    port     = optional(number, null)<br/>    interval = optional(number, 30)<br/>    path     = optional(string, "/")<br/>    protocol = optional(string, "Https")<br/>    timeout  = optional(number, 30)<br/><br/>    unhealthy_threshold                       = optional(number, 3)<br/>    pick_host_name_from_backend_http_settings = optional(bool, false)<br/>    minimum_servers                           = optional(number, 0)<br/><br/>    match = optional(object({<br/>      body        = optional(string, "")<br/>      status_code = optional(list(string), ["200-399"])<br/>    }), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_http_listeners"></a> [http\_listeners](#input\_http\_listeners) | List of objects with HTTP listeners configurations and custom error configurations. | <pre>list(object({<br/>    name = string<br/><br/>    frontend_ip_configuration_name = optional(string)<br/>    frontend_port_name             = optional(string)<br/>    host_name                      = optional(string)<br/>    host_names                     = optional(list(string))<br/>    protocol                       = optional(string, "Https")<br/>    require_sni                    = optional(bool, false)<br/>    ssl_certificate_name           = optional(string)<br/>    ssl_profile_name               = optional(string)<br/>    firewall_policy_id             = optional(string)<br/><br/>    custom_error_configuration = optional(list(object({<br/>      status_code           = string<br/>      custom_error_page_url = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list with a single user managed identity id to be assigned to the Application Gateway | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region where the Application Gateway is created. | `string` | `"uksouth"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Application Gateway. | `string` | n/a | yes |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | Private IP Address to assign to the Load Balancer. | `any` | `null` | no |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | Private Link config for Application Gateway (optional) | <pre>object({<br/>    name                  = string<br/>    ip_configuration_name = string<br/>    subnet_id             = string<br/>    private_ip_address    = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_redirect_configuration"></a> [redirect\_configuration](#input\_redirect\_configuration) | List of objects with redirect configurations. | <pre>list(object({<br/>    name = string<br/><br/>    redirect_type        = optional(string, "Permanent")<br/>    target_listener_name = optional(string)<br/>    target_url           = optional(string)<br/><br/>    include_path         = optional(bool, true)<br/>    include_query_string = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_request_routing_rules"></a> [request\_routing\_rules](#input\_request\_routing\_rules) | List of objects with request routing rules configurations. Priority is required for stability. | <pre>list(object({<br/>    name                        = string<br/>    rule_type                   = optional(string, "Basic")<br/>    http_listener_name          = optional(string)<br/>    backend_address_pool_name   = optional(string)<br/>    backend_http_settings_name  = optional(string)<br/>    url_path_map_name           = optional(string)<br/>    redirect_configuration_name = optional(string)<br/>    rewrite_rule_set_name       = optional(string)<br/>    priority                    = number # Required<br/>  }))</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Application Gateway. | `string` | n/a | yes |
| <a name="input_rewrite_rule_set"></a> [rewrite\_rule\_set](#input\_rewrite\_rule\_set) | List of rewrite rule set objects with rewrite rules. | <pre>list(object({<br/>    name = string<br/>    rewrite_rules = list(object({<br/>      name          = string<br/>      rule_sequence = string<br/><br/>      conditions = optional(list(object({<br/>        variable    = string<br/>        pattern     = string<br/>        ignore_case = optional(bool, false)<br/>        negate      = optional(bool, false)<br/>      })), [])<br/><br/>      response_header_configurations = optional(list(object({<br/>        header_name  = string<br/>        header_value = string<br/>      })), [])<br/><br/>      request_header_configurations = optional(list(object({<br/>        header_name  = string<br/>        header_value = string<br/>      })), [])<br/><br/>      url_reroute = optional(object({<br/>        path         = optional(string)<br/>        query_string = optional(string)<br/>        components   = optional(string)<br/>        reroute      = optional(bool)<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | The sku pricing model of v1 and v2 | <pre>object({<br/>    name     = string<br/>    tier     = string<br/>    capacity = optional(number)<br/>  })</pre> | n/a | yes |
| <a name="input_ssl_certificates"></a> [ssl\_certificates](#input\_ssl\_certificates) | List of SSL certificates data for Application gateway | <pre>list(object({<br/>    name                = string<br/>    data                = optional(string)<br/>    password            = optional(string)<br/>    key_vault_secret_id = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Application Gateway SSL configuration. The list of available policies can be found here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#disabled_protocols | <pre>object({<br/>    disabled_protocols   = optional(list(string), [])<br/>    policy_type          = optional(string, "Predefined")<br/>    policy_name          = optional(string, "AppGwSslPolicy20170401S")<br/>    cipher_suites        = optional(list(string), [])<br/>    min_protocol_version = optional(string, "TLSv1_2")<br/>  })</pre> | `null` | no |
| <a name="input_ssl_profile"></a> [ssl\_profile](#input\_ssl\_profile) | Application Gateway SSL profile. Default profile is used when this variable is set to null. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#name | <pre>object({<br/>    name                             = string<br/>    trusted_client_certificate_names = optional(list(string), [])<br/>    verify_client_cert_issuer_dn     = optional(bool, false)<br/>    ssl_policy = optional(object({<br/>      disabled_protocols   = optional(list(string), [])<br/>      policy_type          = optional(string, "Predefined")<br/>      policy_name          = optional(string, "AppGwSslPolicy20170401S")<br/>      cipher_suites        = optional(list(string), [])<br/>      min_protocol_version = optional(string, "TLSv1_2")<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for attaching the Application Gateway. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_trusted_root_certificates"></a> [trusted\_root\_certificates](#input\_trusted\_root\_certificates) | Trusted root certificates to allow the backend with Azure Application Gateway | <pre>list(object({<br/>    name = string<br/>    data = string<br/>  }))</pre> | `[]` | no |
| <a name="input_url_path_maps"></a> [url\_path\_maps](#input\_url\_path\_maps) | List of objects with URL path map configurations. | <pre>list(object({<br/>    name = string<br/><br/>    default_backend_address_pool_name   = optional(string)<br/>    default_redirect_configuration_name = optional(string)<br/>    default_backend_http_settings_name  = optional(string)<br/>    default_rewrite_rule_set_name       = optional(string)<br/><br/>    path_rules = list(object({<br/>      name = string<br/><br/>      backend_address_pool_name  = optional(string)<br/>      backend_http_settings_name = optional(string)<br/>      rewrite_rule_set_name      = optional(string)<br/><br/>      paths = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_user_assigned_identity_id"></a> [user\_assigned\_identity\_id](#input\_user\_assigned\_identity\_id) | User assigned identity id assigned to this resource. | `string` | `null` | no |
| <a name="input_waf_configuration"></a> [waf\_configuration](#input\_waf\_configuration) | WAF configuration object (only available with WAF\_v2 SKU) with following attributes:<pre>- enabled:                  Boolean to enable WAF.<br/>- file_upload_limit_mb:     The File Upload Limit in MB. Accepted values are in the range 1MB to 500MB.<br/>- firewall_mode:            The Web Application Firewall Mode. Possible values are Detection and Prevention.<br/>- max_request_body_size_kb: The Maximum Request Body Size in KB. Accepted values are in the range 1KB to 128KB.<br/>- request_body_check:       Is Request Body Inspection enabled ?<br/>- rule_set_type:            The Type of the Rule Set used for this Web Application Firewall.<br/>- rule_set_version:         The Version of the Rule Set used for this Web Application Firewall. Possible values are 2.2.9, 3.0, and 3.1.<br/>- disabled_rule_group:      The rule group where specific rules should be disabled. Accepted values can be found here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#rule_group_name<br/>- exclusion:                WAF exclusion rules to exclude header, cookie or GET argument. More informations on: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#match_variable</pre> | <pre>object({<br/>    enabled                  = optional(bool, false)<br/>    file_upload_limit_mb     = optional(number, 100)<br/>    firewall_mode            = optional(string, "Prevention")<br/>    max_request_body_size_kb = optional(number, 128)<br/>    request_body_check       = optional(bool, true)<br/>    rule_set_type            = optional(string, "OWASP")<br/>    rule_set_version         = optional(string, 3.1)<br/>    disabled_rule_group = optional(list(object({<br/>      rule_group_name = string<br/>      rules           = optional(list(string))<br/>    })), [])<br/>    exclusion = optional(list(object({<br/>      match_variable          = string<br/>      selector                = optional(string)<br/>      selector_match_operator = optional(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A collection of availability zones to spread the Application Gateway over. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_appgw_id"></a> [appgw\_id](#output\_appgw\_id) | The ID of the Application Gateway. |
| <a name="output_appgw_name"></a> [appgw\_name](#output\_appgw\_name) | The name of the Application Gateway. |
| <a name="output_backend_address_pool_id"></a> [backend\_address\_pool\_id](#output\_backend\_address\_pool\_id) | The backend address pool id |
<!-- END_TF_DOCS -->
## Contributing

We use pre-commit hooks for validating the terraform format and maintaining the documentation automatically.
Install it with:

```shell
$ brew install pre-commit terraform-docs
$ pre-commit install
```

If you add a new hook make sure to run it against all files:
```shell
$ pre-commit run --all-files
```
