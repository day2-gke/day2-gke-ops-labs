# Introduction to Config Sync Challenge Lab

## Overview

Config Sync is a GitOps service built on an open source core that lets cluster operators and platform administrators deploy configurations from Git, OCI, or Helm repositories. The service has the flexibility to support one or many clusters and any number of repositories per cluster or namespace. The clusters can be in a hybrid or multi-cloud environment.

## Config Sync

GitOps is considered a universal best practice for organizations managing Kubernetes configuration as scale. The benefits of improved stability, better readability, consistency, audit and security are common to all GitOps tools. Config Sync is a service which provides you with a set of unique advantages:

- Integrated: platform admins can install Config Sync using a few clicks in the Google Cloud console, using Terraform, or by using Google Cloud CLI on any cluster connected to your fleet. The service is pre-configured to work with other Google Cloud services like Policy Controller, Workload Identity and Cloud Monitoring.
- Built-in observability: Config Sync has an observability dashboard that is built into the Google Cloud console, requiring no additional setup. Platform administrators can view the state of their synchronization and reconciliation by visiting the Google Cloud console or by using the Google Cloud CLI.
- Multi-cloud and hybrid support: Config Sync is tested across several cloud providers and in hybrid environments prior to every GA release. To view the support matrix, see Version and upgrade support.

## Enable GKE Workload Identity

GKE creates a fixed workload identity pool for each Google Cloud project, with the format `PROJECT_ID.svc.id.goog.`

1. Check if GKE Workload Identity is enabled
2. Enable Workload Identity on the `dev-cluster` and `prod-cluster`

**Docs:**

- [Enable Workload Identity on GKE](https://cloud.google.com/sdk/gcloud/reference/container/clusters/update#--workload-pool)
- [Verify GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/describe)

**Caution**: Modifying a node pool immediately enables GKE Workload Identity for any workloads running in the node pool. This prevents the workloads from using the Compute Engine default service account and might result in disruptions. You can selectively disable GKE Workload Identity on a specific node pool by explicitly specifying --workload-metadata=GCE_METADATA. See Protecting cluster metadata for more information.

## Register clusters to the Fleet Host Project

The implementation of fleets, like many other Google Cloud resources, is rooted in a Google Cloud project, which we refer to as the fleet host project. A given Cloud project can only have a single fleet (or no fleets) associated with it. This restriction reinforces using Cloud projects to provide stronger isolation between resources that are not governed or consumed together.

For this lab the fleet host project is the same project where the clusters were created.

1. Verify the fleet memberships
2. Register the `dev-cluster` and `prod-cluster`

**Docs:**

- [Manage GKE Fleet Memberships Workload Identity on GKE](https://cloud.google.com/sdk/gcloud/reference/container/fleet/memberships/)

## Install Config Sync

For this lab we will install Config Sync and configure it to use the configs in the config-sync-quickstart directory of the GoogleCloudPlatform/anthos-config-management-samples repository.

1. Enable the Config Management Feature
2. Create a new `apply-spec.yaml` manifest
   ```
   mkdir -p ${HOME}/config-sync && \
   cat <<EOF > ${HOME}/config-sync/apply-spec.yaml
   applySpecVersion: 1
   spec:
   configSync:
       enabled: true
       policyDir: /config-sync-quickstart/multirepo/root
       secretType: none
       sourceFormat: unstructured
       syncBranch: main
       syncRepo: https://github.com/GoogleCloudPlatform/anthos-config-management-samples
   EOF
   ```
3. Apply configuration to the `dev-cluster` and `prod-cluster`
4. Verify the status of the Config Sync installation
5. Verify synchornised namespaces

**Docs:**

- [Manage Config Management Feature](https://cloud.google.com/sdk/gcloud/reference/beta/container/hub/config-management)
- [Apply Config Management Feature Spec](https://cloud.google.com/sdk/gcloud/reference/beta/container/fleet/config-management/apply)
