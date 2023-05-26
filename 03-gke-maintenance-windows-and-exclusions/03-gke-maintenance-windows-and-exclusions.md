# Caveats about maintenance windows and exclusions
Maintenance windows and exclusions can cause security patches to be delayed. GKE reserves the right to override maintenance policies for critical security vulnerabilities. Before enabling maintenance windows and exclusions, make sure you understand the following caveats.

## Other Google Cloud maintenance
GKE clusters and workloads can also be impacted by automatic maintenance on other, dependent services, such as Compute Engine. GKE maintenance windows and exclusions do not prevent automatic maintenance from other Google services, or services which install applications to the cluster, such as Google Cloud Deploy.

## Automated repairs and resizing
GKE performs automated repairs on control planes. This includes processes like upscaling the control plane to an appropriate size or restarting the control plane to resolve issues. Most repairs ignore maintenance windows and exclusions because failing to perform the repairs can result in non-functional clusters. Repairing control planes cannot be disabled.

> Note: Regional clusters have multiple replicas of the control plane, allowing for high availability of the Kubernetes API server even during maintenance events.

Nodes also have auto-repair functionality, but can be disabled.

## Node re-creation and maintenance windows
When you enable or modify features or options such as those that impact networking between the control planes and nodes, the nodes are recreated to apply the new configuration. Some examples of features that cause nodes to be recreated are as follows:

- Shielded nodes
- Network policies
- Intranode visibility
- NodeLocal DNSCache
- Rotating the control plane's IP address
- Rotating the control plane's credentials

If you use maintenance windows or exclusions and you enable or modify a feature or option that requires nodes to be recreated, the new configuration is applied to the nodes only when node maintenance is allowed. If you prefer not to wait, you can manually apply the changes to the nodes by calling the gcloud container clusters upgrade command and passing the --cluster-version flag with the same GKE version that the node pool is already running. You must use the Google Cloud CLI for this workaround.

# Maintenance windows
Maintenance windows allow you to control when automatic upgrades of control planes and nodes can occur, to mitigate potential transient disruptions to your workloads. Maintenance windows are useful for the following types of scenarios, among others:

- Off-peak hours: You want to minimize the chance of downtime by scheduling automatic upgrades during off-peak hours when traffic is reduced.
- On-call: You want to ensure that upgrades happen during working hours so that someone can monitor the upgrades and manage any unanticipated issues.
-  Multi-cluster upgrades: You want to roll out upgrades across multiple clusters in different regions one at a time at specified intervals.
In addition to automatic upgrades, Google may occasionally need to perform other maintenance tasks, and honors a cluster's maintenance window if possible.

If tasks run beyond the maintenance window, GKE attempts to pause the tasks, and attempts to resume those tasks during the next maintenance window.

GKE reserves the right to roll out unplanned emergency upgrades outside of maintenance windows. Additionally, mandatory upgrades from deprecated or outdated software might automatically occur outside of maintenance windows.

> Note: You can also manually upgrade your cluster at any time. Manually-initiated upgrades begin immediately and ignore any maintenance windows.

## Restrictions
Maintenance windows have the following restrictions:

### One maintenance window per cluster
You can only configure a single maintenance window per cluster. Configuring a new maintenance window overwrites the previous one.

### Time zones for maintenance windows
When configuring and viewing maintenance windows, times are shown differently depending on the tool you are using:

When configuring maintenance windows
When configuring maintenance windows using the more generic --maintenance-window flag, you cannot specify a time zone. UTC is used when using the gcloud CLI or the API, and Google Cloud console displays times using the local time zone.

When using more granular flags, such as --maintenance-window-start, you can specify the time zone as part of the value. If you omit the time zone, your local time zone is used. Times are always stored in UTC.

**When viewing maintenance windows** 
When viewing information about your cluster, timestamps for maintenance windows may be shown in UTC or in your local time zone, depending on how you are viewing the information:

- When using Google Cloud console to view information about your cluster, times are always displayed in your local time zone.
- When using the gcloud CLI to view information about your cluster, times are always shown in UTC.
In both cases, the RFC-5545 RRULE is always in UTC. That means that if specifying, for example, days of the week, then those days are in UTC.

# Configuring a maintenance windows
To configure a maintenance window, you configure when it starts, how long it lasts, and how often it repeats. For example, you can configure a maintenance window that recurs weekly on Monday through Friday. You must allow at least 48 hours of maintenance availability in a 32-day rolling window. Only contiguous availability windows of at least four hours are considered.

### Configure a maintenance window for an existing cluster
To create or update a maintenance window for existing-cluster on Monday to Friday starting at 00:00 Central Standard Time (CST) and lasting four hours, run the following command:
```
gcloud container clusters update existing-cluster \
--maintenance-window-start 1970-01-01T00:00:00-06:00 \
--maintenance-window-end 1970-01-01T04:00:00-06:00 \
--maintenance-window-recurrence 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'  \
--zone <your-zone>
```
**Flags**
  1. --maintenance-window-start: when to start the maintenance window, expressed as an RFC-5545 DTSTART value.
  2. --maintenance-window-end: when to end the maintenance window, specified in the same format as --maintenance-window-start, but is only used to calculate the duration of the maintenance window. The value must be in the future, relative to --maintenance-window-start.
  3. --maintenance-window-recurrence: an RFC-5545 RRULE. This is an extremely flexible format with multiple ways to specify recurrence rules.


- Verify existing-cluster has the maintenance window configured
```
gcloud container clusters describe existing-cluster \
--zone=<your-zone> | grep -A 4 recurringWindow
```

- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > existing-cluster or run the following command and click on the URL
```
echo -e "\nexisting-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/<your-zone>/existing-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```
In the **Automation** section there is a **Maintenance window** entry that shows the configured settings.

## Create a cluster with a simple maintenance window
- To create simple-maintenance-window-cluster with a simple maintenance window that runs each day starting at 5:00 UTC or 00:00 Central Standard Time (CST) and lasting four hours, run the following command:
```
gcloud container clusters create simple-maintenance-window-cluster \
--maintenance-window 5:00 \
--num-nodes=1 \
--zone=<your-zone>
```
- Verify simple-maintenance-window-cluster has the maintenance window configured
```
gcloud container clusters describe simple-maintenance-window-cluster \
--zone=<your-zone> | grep -A 2 dailyMaintenanceWindow
```
