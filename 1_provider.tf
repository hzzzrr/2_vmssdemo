terraform {
  required_providers {
    # azurerm Provider 用来管理和创建azure资源
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.34.0"
      }

    # local Provider 用来创建本地文件，写入kubeconfig文件等
    local = {
      source = "hashicorp/local"
      version = "2.5.3"
    }
  }
  
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {

    resource_group {
      prevent_deletion_if_contains_resources = false
    }

  }
    subscription_id = var.subscription-id
}
