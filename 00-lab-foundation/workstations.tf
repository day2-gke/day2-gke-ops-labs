# Copyright 2023 Google LLC

resource "google_workstations_workstation_cluster" "default" {
  provider               = google-beta.robot-account
  project                = var.deploy_project
  workstation_cluster_id = "workstation-cluster"
  network                = google_compute_network.gke_day2_ops.id
  subnetwork             = google_compute_subnetwork.workstations.id
  location               = var.deploy_region
  depends_on             = [time_sleep.apis_propagation]

  labels = {
    "workstation" = "lab-workstation"
  }

}

resource "google_workstations_workstation_config" "default" {
  provider               = google-beta.robot-account
  project                = var.deploy_project
  workstation_config_id  = "workstation-config"
  workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
  location               = var.deploy_region
  depends_on             = [time_sleep.apis_propagation]
  host {
    gce_instance {
      machine_type      = "e2-standard-4"
      boot_disk_size_gb = 35
    }
  }

  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = 200
      reclaim_policy = "DELETE"
    }
  }
}

resource "google_workstations_workstation" "default" {
  provider               = google-beta
  project                = var.deploy_project
  workstation_id         = "lab-workstation"
  workstation_config_id  = google_workstations_workstation_config.default.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
  location               = var.deploy_region
  depends_on             = [time_sleep.apis_propagation]

  labels = {
    "lab" = "workstation"
  }
}
