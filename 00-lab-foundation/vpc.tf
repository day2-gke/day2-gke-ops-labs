# Copyright 2023 Google LLC

resource "google_compute_network" "gke_day2_ops" {
  name                    = "gke-day2-ops"
  auto_create_subnetworks = false
  depends_on              = [time_sleep.apis_propagation]
}

resource "google_compute_subnetwork" "workstations" {
  name          = "workstation-cluster"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.deploy_region
  network       = google_compute_network.gke_day2_ops.name
  depends_on    = [time_sleep.apis_propagation]
}

resource "google_compute_subnetwork" "gke" {
  name          = "gke-primary"
  ip_cidr_range = "10.100.0.0/24"
  region        = var.deploy_region
  network       = google_compute_network.gke_day2_ops.name
  depends_on    = [time_sleep.apis_propagation]
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.100.8.0/21"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.100.16.0/21"
  }
}
