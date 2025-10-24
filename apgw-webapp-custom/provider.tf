terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.47.0"
    }
  }
}
provider "azurerm" {
  features {
    application_insights {
      disable_generated_rule = true
    }
  }
}