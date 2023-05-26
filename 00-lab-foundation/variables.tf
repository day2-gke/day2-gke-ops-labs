# Copyright 2023 Google LLC

variable "deploy_project" {
  type        = string
  description = "The Google Cloud Project to deploy the resources to."
}

variable "deploy_region" {
  type        = string
  description = "The Google Cloud Region to deploy the resources to."
  default     = "europe-west2"
}
