# Lab Foundations Deployment

This folder contains the Terraform configuration required to deploy the foundational services for the Day 2 GKE Ops Labs to you Google Cloud Project.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/downloads) configured and installed
- [gcloud](https://cloud.google.com/sdk/gcloud/) configured and authenticated with your account (`gcloud auth login`)

## Instructions

1. Copy `terraform.tfvars.example` to `terraform.tfvars`, updating your Google Cloud Project variable as appropriate
2. Run `terraform init`
3. Run `terraform apply`
4. Open your Google Cloud project and start the workstation
