resource "azurerm_container_app_environment" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.container_app_environment.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_container_app_environment_storage" "this" {
  name                         = "n8nconfig"
  access_key                   = module.storage.resource.primary_access_key
  access_mode                  = "ReadWrite"
  account_name                 = module.storage.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  share_name                   = "n8nconfig"
}

module "container_app" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.4.0"

  name                                  = module.naming.container_app.name_unique
  resource_group_name                   = azurerm_resource_group.this.name
  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  enable_telemetry                      = var.enable_telemetry
  revision_mode                         = "Single"
  tags                                  = var.tags

  template = {
    containers = [
      {
        name   = "n8n"
        memory = "0.5Gi"
        cpu    = 0.25
        image  = "docker.io/n8nio/n8n:latest"

        env = [
          {
            name  = "DB_TYPE"
            value = "postgresdb"
          },
          {
            name  = "DB_POSTGRESDB_HOST"
            value = module.postgresql.fqdn
          },
          {
            name  = "DB_POSTGRESDB_PORT"
            value = "5432"
          },
          {
            name  = "DB_POSTGRESDB_DATABASE"
            value = "n8n"
          },
          {
            name  = "DB_POSTGRESDB_USER"
            value = "psqladmin"
          },
          {
            name        = "DB_POSTGRESDB_PASSWORD"
            secret_name = "dbpassword"
          },
          {
            name  = "N8N_PROTOCOL"
            value = "http"
          },
          {
            name  = "N8N_PORT"
            value = "5678"
          },
          {
            name  = "N8N_RUNNERS_ENABLED"
            value = "true"
          },
          {
            name  = "WEBHOOK_URL"
            value = "https://${azurerm_container_app_environment.this.name}.${azurerm_container_app_environment.this.default_domain}"
          },
          {
            name  = "DB_POSTGRESDB_SSL_ENABLED"
            value = "true"
          },
          {
            name  = "AZURE_CLIENT_ID"
            value = azurerm_user_assigned_identity.this.client_id
          },
          {
            name  = "AZURE_TENANT_ID"
            value = data.azurerm_client_config.current.tenant_id
          },
          {
            name  = "APPSETTING_WEBSITE_SITE_NAME"
            value = "azcli-workaround"
          }
        ]

        volume_mounts = [
          {
            name = "n8nconfig"
            path = "/home/node/.n8n"
          }
        ]
      }
    ]

    volumes = [
      {
        name         = "n8nconfig"
        storage_type = "AzureFile"
        storage_name = azurerm_container_app_environment_storage.this.name
        #mount_options = "dir_mode=0600,file_mode=0600,uid=1000,gid=1000"
      }
    ]
  }

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }

  ingress = {
    allow_insecure_connections = false
    client_certificate_mode    = "ignore"
    external_enabled           = true
    target_port                = 5678
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  secrets = {
    db_password = {
      name                = "dbpassword"
      key_vault_secret_id = module.key_vault.secrets_resource_ids["psqladmin-password"].id
      identity            = azurerm_user_assigned_identity.this.id
    }
  }
}
