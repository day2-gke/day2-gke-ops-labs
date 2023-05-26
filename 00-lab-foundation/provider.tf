# Copyright 2023 Google LLC

// Define the default Google provider, which is used for deploying most of the
// resources in this Terraform
provider "google" {
  project = var.deploy_project
  region  = var.deploy_region
}

// Define the Google Beta provider, with a Billing Project override to enable
provider "google-beta" {
  alias           = "robot-account"
  project         = var.deploy_project
  region          = var.deploy_region
  request_timeout = "60s"
}

// Pin provider resource
terraform {
  required_providers {
    google-beta = {
      version = "~> 4.60.2"
    }
    google = {
      version = "~> 4.60.2"
    }
  }
}
