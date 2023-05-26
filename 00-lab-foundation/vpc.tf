# Copyright 2023 Google LLC

resource "google_compute_network" "gke_day2_ops" {
  name                    = "gke-day2-ops"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "workstations" {
  name          = "workstation-cluster"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.deploy_region
  network       = google_compute_network.gke_day2_ops.name
}

resource "google_compute_subnetwork" "gke" {
  name          = "gke-primary"
  ip_cidr_range = "10.100.0.0/24"
  region        = var.deploy_region
  network       = google_compute_network.gke_day2_ops.name
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.100.1.0/24"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.100.2.0/24"
  }
}
