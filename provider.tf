terraform {

  required_providers {

    azurerm = {

      source = "hashicorp/azurerm"

      version = "3.107.0"

    }

  }

}

provider "azurerm" {

  # subscription_id = "8063ac5c-b4d0-XXXXXXXXXXXXXXXXX"

  # tenant_id = "261f0e27-7129-XXXXXXXXXXXXXX"

  # client_id = "1b05de14-66f4-XXXXXXXXXXXXXX"

  # client_secret = "tJR8Q~URCKqkafQNJG~-XXXXXXXXXXXXX

  features {}

}
