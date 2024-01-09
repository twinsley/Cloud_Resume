# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.86.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
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
  custom_domain {
    name = "resume.twinsley.com"
  }

  tags = var.resource_tags
}
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_prefix}${var.project_name}"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.resource_tags
}
