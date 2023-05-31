# Copyright 2023 Google LLC

// Enable the required Google Cloud API's for the Drone Derby Infrastructure
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "stackdriver.googleapis.com",
    "pubsub.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkebackup.googleapis.com",
    "gkehub.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "workstations.googleapis.com"
  ])
  project                    = var.deploy_project
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

// Wait a little while for the API's to enable consistently
resource "time_sleep" "apis_propagation" {
  depends_on = [
    google_project_service.apis,
  ]
  create_duration = "240s"
}
