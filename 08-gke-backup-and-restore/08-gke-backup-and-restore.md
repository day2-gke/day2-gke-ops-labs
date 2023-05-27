# Overview
Backup for GKE is a service for backing up and restoring workloads in GKE clusters. It has two components:

A Google Cloud API serves as the control plane for the service.
A GKE add-on (the Backup for GKE agent) must be enabled in each cluster for which you wish to perform backup and restore operations.
Backups of your workloads may be useful for disaster recovery, CI/CD pipelines, cloning workloads, or upgrade scenarios. Protecting your workloads can help you achieve business-critical recovery point objectives.

## What you'll learn
In this lab, you will learn how to:

- Enable Backup for a GKE cluster
- Deploy a stateful application with a database on GKE
- Plan and backup GKE workloads
- Restore a backup

