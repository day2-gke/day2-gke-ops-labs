# GKE Maintenance Windows and Exclusions Challenge Lab

## Overview

Maintenance windows and exclusions give you fine-grained control over when automatic maintenance can occur on your clusters.

A maintenance windows is a repeating window of time during which automatic maintenance is permitted. A maintenance exclusions is a non-repeating window of time during which automatic maintenance is forbidden.

You can configure maintenance windows and maintenance exclusions separately and independently as well as being able to configure multiple maintenance exclusions.

_Note: To ensure that your clusters remain functional, your configured maintenance windows and maintenance exclusions do not block control plane repair operations._

### Examples of automatic GKE maintenance

Google performs maintenance tasks on your clusters as needed, or when you make a configuration change that re-creates nodes or networks in the cluster, such as the following:
- Auto-upgrades to cluster control planes in accordance with the GKE versioning and support policy.
- Node auto-upgrades, if enabled.
- User-initiated configuration changes that cause nodes to be re-created, such as GKE Sandbox.
- User-initiated configuration changes that fundamentally change the cluster's internal network topology, such as optimizing IP address allocation.

Zonal clusters cannot be modified during control plane configuration changes and cluster maintenance. This includes deploying workloads.

Each of the other types of changes listed above can cause temporary disruptions while workloads are migrated to upgraded nodes.


## What you will learn
In this lab, you will learn how to do the following:

- Configure maintenance windows for an existing GKE cluster
- Configure maintenance exclusions for an existing GKE cluster

## Caveats about maintenance windows and exclusions

Maintenance windows and exclusions can cause security patches to be delayed. GKE reserves the right to override maintenance policies for critical security vulnerabilities. Before enabling maintenance windows and exclusions, make sure you understand the following caveats.

### Other Google Cloud maintenance
GKE clusters and workloads can also be impacted by automatic maintenance on other, dependent services, such as Compute Engine. GKE maintenance windows and exclusions do not prevent automatic maintenance from other Google services, or services which install applications to the cluster, such as Google Cloud Deploy.

### Automated repairs and resizing
GKE performs automated repairs on control planes. This includes processes like upscaling the control plane to an appropriate size or restarting the control plane to resolve issues. Most repairs ignore maintenance windows and exclusions because failing to perform the repairs can result in non-functional clusters. Repairing control planes cannot be disabled.

Note: Regional clusters have multiple replicas of the control plane, allowing for high availability of the Kubernetes API server even during maintenance events.

Nodes also have auto-repair functionality, but can be disabled.

### Node re-creation and maintenance windows
When you enable or modify features or options such as those that impact networking between the control planes and nodes, the nodes are recreated to apply the new configuration. Some examples of features that cause nodes to be recreated are as follows:

- Shielded nodes
- Network policies
- Intranode visibility
- NodeLocal DNSCache
- Rotating the control plane's IP address
- Rotating the control plane's credentials

If you use maintenance windows or exclusions and you enable or modify a feature or option that requires nodes to be recreated, the new configuration is applied to the nodes only when node maintenance is allowed. If you prefer not to wait, you can manually apply the changes to the nodes by calling the gcloud container clusters upgrade command and passing the --cluster-version flag with the same GKE version that the node pool is already running. You must use the Google Cloud CLI for this workaround.

## Configuring a maintenance windows
To configure a maintenance window, you configure when it starts, how long it lasts, and how often it repeats. For example, you can configure a maintenance window that recurs weekly on Monday through Friday. You must allow at least 48 hours of maintenance availability in a 32-day rolling window. Only contiguous availability windows of at least four hours are considered.

### Configure a maintenance window for an existing cluster
1. Create a maintenance window for the **prod-cluster** on Monday to Friday starting at 00:00 Greenwich Mean Time (GMT) and lasting four hours
2. Verify the `prod-cluster` has the maintenance window configured (hint: you can verify this in the console and via gcloud commands)
3. Remove the maintenance window from the `prod-cluster`
4. Verify the maintenance window has been removed

**Docs:**

- [Maintenance Windows](https://cloud.google.com/kubernetes-engine/docs/how-to/maintenance-windows-and-exclusions#gcloud_1)

## Maintenance Exclusions
With maintenance exclusions, you can prevent automatic maintenance from occurring during a specific time period. For example, many retail businesses have business guidelines prohibiting infrastructure changes during the end-of-year holidays. As another example, if a company is using an API that is scheduled for deprecation, they can use maintenance exclusions to pause minor upgrades to give them time to migrate applications.

For known high-impact events, we recommend that you match any internal change restrictions with a maintenance exclusion that starts one week before the event and lasts for the duration of the event.

Exclusions have no recurrence. Instead, create each instance of a periodic exclusion separately.

When exclusions and maintenance windows overlap, exclusions have precedence.

### Scope of maintenance to exclude
Not only can you specify when to prevent automatic maintenance on your cluster, you can restrict the scope of automatic updates that might occur. Maintenance exclusion scopes are useful for the following types of scenarios, among others:

- No upgrades - avoid any maintenance: You want to temporarily avoid any change to your cluster during a specific period of time.
- No minor upgrades - maintain current Kubernetes minor version: You want to temporarily maintain the minor version of a cluster to avoid API changes or validate the next minor version.
- No minor or node upgrades - prevent node pool disruption: You want to temporarily avoid any eviction and rescheduling of your workloads because of node upgrades.

### Multiple exclusions
You may set multiple exclusions on a cluster. These exclusions may have different scopes and may have overlapping time ranges. The end-of-year holiday season use case is an example of overlapping exclusions, where both the "No upgrades" and "No minor upgrades" scopes are in use.

When exclusions overlap, if any active exclusion (that is, current time is within the exclusion time period) blocks an upgrade, the upgrade will be postponed.

## Configuring a maintenance exclusion
1. Create a maintenance exclusion for the `prod-cluster` from Black Friday 2021 (November 26, 2021) to Cyber Monday 2021 (November 29, 2021), from midnight Eastern (UTC-5) to 23:59:59 Pacific (UTC-8)

**Docs:**

- [Create Maintenance Exclusion](https://cloud.google.com/kubernetes-engine/docs/how-to/maintenance-windows-and-exclusions#configuring_a_maintenance_exclusion)
- [Black Friday Maintenance Exclusion Example](https://cloud.google.com/kubernetes-engine/docs/how-to/maintenance-windows-and-exclusions#example-maintenance-exclusions)