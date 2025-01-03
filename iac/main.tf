# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "tfstate27696"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
      use_azuread_auth     = true   
  }


  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id = "c8bf815a-c370-4cbf-932f-c6d7340752f6"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}${var.project_name}"
  location = var.region
  tags     = var.resource_tags
}

resource "azurerm_storage_account" "st" {
  name                     = "${var.storage_account_name}${var.project_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  static_website {
    index_document = "index.html"
  }

  tags = var.resource_tags
}
resource "azurerm_storage_table" "example" {
  name                 = "ResumeCounter"
  storage_account_name = azurerm_storage_account.st.name
}

resource "azurerm_cdn_profile" "cdn" {
  name                = "cdn${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdnendpoint" {
  name                = "cdnep${var.project_name}"
  profile_name        = azurerm_cdn_profile.cdn.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  origin_host_header = azurerm_storage_account.st.primary_web_host

  origin {
    name      = "st"
    host_name = azurerm_storage_account.st.primary_web_host
    
  }

  delivery_rule {
    name  = "HTTP"
    order = 1
    request_scheme_condition {
      match_values = ["HTTP"]
    }
    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }
  is_compression_enabled = true
  content_types_to_compress = [
    "application/eot",
    "application/font",
    "application/font-sfnt",
    "application/javascript",
    "application/json",
    "application/opentype",
    "application/otf",
    "application/pkcs7-mime",
    "application/truetype",
    "application/ttf",
    "application/vnd.ms-fontobject",
    "application/xhtml+xml",
    "application/xml",
    "application/xml+rss",
    "application/x-font-opentype",
    "application/x-font-truetype",
    "application/x-font-ttf",
    "application/x-httpd-cgi",
    "application/x-javascript",
    "application/x-mpegurl",
    "application/x-opentype",
    "application/x-otf",
    "application/x-perl",
    "application/x-ttf",
    "font/eot",
    "font/ttf",
    "font/otf",
    "font/opentype",
    "image/svg+xml",
    "text/css",
    "text/csv",
    "text/html",
    "text/javascript",
    "text/js",
    "text/plain",
    "text/richtext",
    "text/tab-separated-values",
    "text/xml",
    "text/x-script",
    "text/x-component",
    "text/x-java-source",
  ]
}

resource "azurerm_cdn_endpoint_custom_domain" "example" {
  name            = "cdnecd${var.project_name}"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdnendpoint.id
  host_name       = "resume.twinsley.com"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}

resource "azurerm_service_plan" "asp" {
  name                = "asp${var.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  os_type             = "Linux"
  sku_name            = "Y1"
  tags = var.resource_tags
}

resource "azurerm_linux_function_app" "api" {
  name = "func${var.project_name}"
  storage_account_name = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  service_plan_id = azurerm_service_plan.asp.id
  tags = var.resource_tags

  site_config {
    application_stack {
      dotnet_version = "8.0"
      use_dotnet_isolated_runtime = true
  }
  cors {
    allowed_origins = [
        "https://127.0.0.1:5000",
        "https://localhost:5000",
        "https://resume.twinsley.com",
        "https://sttwcus0cloudresume1.z19.web.core.windows.net",
    ]
    support_credentials = false
  }
  ip_restriction {
    ip_address = "23.92.31.61/32"
    action = "Allow"
    description = "Linode NGINX"
  }
  ip_restriction_default_action = "Deny"
    
  }
  app_settings = {
    "AZURE_STORAGETABLE_RESOURCEENDPOINT": "https://sttwcus0cloudresume1.table.core.windows.net/",
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE": "false",
    "WEBSITE_RUN_FROM_PACKAGE": "placeholder"
    }
       lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "example" {
  scope                = resource.azurerm_storage_account.st.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = resource.azurerm_linux_function_app.api.identity[0].principal_id
}
