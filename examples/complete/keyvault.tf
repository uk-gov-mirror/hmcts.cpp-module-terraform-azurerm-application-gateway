data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "test" {
  name                = "tf-test-kv-${random_id.prefix.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.test_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = ["172.187.249.214"] # Outbound IP from ADO VMSS to keyvault need to look into adding static range.
    virtual_network_subnet_ids = [module.test_appgw_subnet.id]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]

    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.app-gw-identity.principal_id

    key_permissions = [
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]

    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"
    ]
  }

  tags = var.tags
}

# Generating a auto-renewing self signed certificate
resource "azurerm_key_vault_certificate" "self_signed_certificate" {
  name         = "self-signed-certificate"
  key_vault_id = azurerm_key_vault.test.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=test.com"
      validity_in_months = 12
    }
  }
}
