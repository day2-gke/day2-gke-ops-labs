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
- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > simple-maintenance-window-cluster or run the following command and click on the URL
```
echo -e "\nsimple-maintenance-window-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/<your-zone>/simple-maintenance-window-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```
In the Automation section there is a Maintenance window entry that shows the configured settings.

## Remove a maintenance window
- To remove the existing maintenance windows on existing-cluster, run the following command:
```
gcloud container clusters update existing-cluster \
--clear-maintenance-window \
--zone <your-zone>
```

- Verify existing-cluster has the maintenance window removed
```
gcloud container clusters describe existing-cluster \
--zone=us-central1-a | grep -A 4 recurringWindow
```              
- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > existing-cluster or run the following command and click on the URL
```
echo -e "\nexisting-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/existing-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```
In the Automation section there is a Maintenance window entry that shows the settings are removed.

# Maintenance exclusions
With maintenance exclusions, you can prevent automatic maintenance from occurring during a specific time period. For example, many retail businesses have business guidelines prohibiting infrastructure changes during the end-of-year holidays. As another example, if a company is using an API that is scheduled for deprecation, they can use maintenance exclusions to pause minor upgrades to give them time to migrate applications.

For known high-impact events, we recommend that you match any internal change restrictions with a maintenance exclusion that starts one week before the event and lasts for the duration of the event.

Exclusions have no recurrence. Instead, create each instance of a periodic exclusion separately.

When exclusions and maintenance windows overlap, exclusions have precedence.

To learn how to set up maintenance exclusions for a new or existing cluster, see Configure a maintenance exclusion.

## Scope of maintenance to exclude
Not only can you specify when to prevent automatic maintenance on your cluster, you can restrict the scope of automatic updates that might occur. Maintenance exclusion scopes are useful for the following types of scenarios, among others:

- No upgrades - avoid any maintenance: You want to temporarily avoid any change to your cluster during a specific period of time.
- No minor upgrades - maintain current Kubernetes minor version: You want to temporarily maintain the minor version of a cluster to avoid API changes or validate the next minor version.
- No minor or node upgrades - prevent node pool disruption: You want to temporarily avoid any eviction and rescheduling of your workloads because of node upgrades.

The following table lists the scope of automatic updates that you can restrict in a maintenance exclusion. The table also indicates what type of upgrades that occur (minor and/or patch). When upgrades occur, the VM(s) for the control plane and/or node pool restarts. For control planes, VM restarts may temporarily decrease the Kubernetes API Server availability, especially in zonal cluster topology with a single control plane. For nodes, VM restarts trigger Pod rescheduling which can temporarily disrupt existing workloads. You can set your tolerance for workload disruption using a Pod Disruption Budget (PDB).

For definitions on minor and patch versions, see Versioning scheme.

## Multiple exclusions
You may set multiple exclusions on a cluster. These exclusions may have different scopes and may have overlapping time ranges. The end-of-year holiday season use case is an example of overlapping exclusions, where both the "No upgrades" and "No minor upgrades" scopes are in use.

When exclusions overlap, if any active exclusion (that is, current time is within the exclusion time period) blocks an upgrade, the upgrade will be postponed.

Using the end-of-year holiday season use case, a cluster has the following exclusions specified:

- No minor upgrades: September 30 - January 15
- No upgrades: November 19 - December 4
- No upgrades: December 15 - January 5
As a result of these overlapping exclusions, the following upgrades will be blocked on the cluster:

- Patch upgrade to the node pool on November 25 (rejected by "No upgrades" exclusion)
- Minor upgrade to the control plane on December 20 (rejected by "No minor upgrades" and "No upgrades" exclusion)
- Patch upgrade to the control plane on December 25 (rejected by "No upgrades" exclusion)
- Minor upgrade to the node pool on January 1 (rejected by "No minor upgrades" and "No upgrades" exclusion)
The following maintenance would be permitted on the cluster:

- Patch upgrade to the control plane on November 10 (permitted by "No minor upgrades" exclusion)
- VM disruption due to GKE maintenance on December 10 (permitted by "No minor upgrades" exclusion)

## Exclusion expiration
When an exclusion expires (that is, the current time has moved beyond the end time specified for the exclusion), that exclusion will no longer prevent GKE updates. Other exclusions that are still valid (not expired) will continue to prevent GKE updates.

When no exclusions remain that prevent cluster upgrades, your cluster will gradually upgrade to the current default version in the cluster's release channel (or the static default for clusters in no release channel).

If your cluster is multiple minor versions behind the current default version after exclusion expiry, GKE will schedule one minor upgrade per month (upgrading both cluster control plane and nodes) until your cluster has reached the default version for the Release Channel. If you would like to return your cluster to the default version sooner, you can execute manual upgrades.

## Limitations
Maintenance exclusions have the following limitations:

- You can restrict the scope of automatic upgrades in a maintenance exclusion only for clusters that are enrolled in a release channel. The maintenance exclusion defaults to the "No upgrades" scope.

- You can add a maximum of three maintenance exclusions that exclude all upgrades (that is, a scope of "no upgrades"). These exclusions must be configured to allow for at least 48 hours of maintenance availability in a 32-day rolling window.

- You can have a maximum of 20 maintenance exclusions in total.

- If you do not specify a scope in your exclusion, the scope defaults to "no upgrades".

- The length of a maintenance exclusion has restrictions based on the specified exclusion scope:
  - No upgrades: Cannot exceed 30 days.
  - No minor upgrades: Cannot end more than 180 days after the exclusion creation date, or extend past the end of life date of the minor version.
  - No minor or node upgrades: Cannot end more than 180 days after the exclusion creation date, or extend past the end of life date of the minor version.
 
## Usage examples
Here are some example use cases for restricting the scope of updates that can occur.

**Example: Retailer preparing for the end-of-year holiday season**
In this example, the retail business does not want disruptions during the highest-volume sales periods, which is the four days encompassing Black Friday through Cyber Monday, and the month of December until the start of the new year. In preparation for the shopping season, the cluster administrator sets up the following exclusions:

- No minor upgrades: Allow only patch updates on the control plane and nodes between September 30 - January 15.
- No upgrades: Freeze all upgrades between November 19 - December 4.
- No upgrades: Freeze all upgrades between December 15 - January 5.
If no other exclusion windows apply when the maintenance exclusion expires, the cluster is upgraded to a new GKE minor version if one was made available between September 30 and January 6.

**Example: Company using a beta API in Kubernetes that's being removed**
In this example, a company is using the CustomResourceDefinition apiextensions.k8s.io/v1beta1 API, which will be removed in version 1.22. While the company is running versions earlier than 1.22, the cluster administrator sets up the following exclusion:

- No minor upgrades: Freeze minor upgrades for three months while migrating customer applications from apiextensions.k8s.io/v1beta1 to apiextensions.k8s.io/v1.

**Example: Company's legacy database not resilient to node pool upgrades**
In this example, a company is running a database that does not respond well to Pod evictions and rescheduling that occurs during a node pool upgrade. The cluster administrator sets up the following exclusion:

- No minor or node upgrades: Freeze node upgrades for three months. When the company is ready to accept downtime for the database, they trigger a manual node upgrade.

# Configuring a maintenance exclusion
To set up a maintenance exclusion for your cluster, you need to specify the following:

- Name: The name of the exclusion (optional).
- Start time: The date and time for when the exclusion period should start.
- End time: The date and time for when the exclusion period should end. Refer to the following table for restrictions on the length of an exclusion period for each of the available scopes.
- Scope: The scope of automatic upgrades to restrict. Refer to the following table that lists the available exclusion scopes.

For definitions on minor and patch versions, see Versioning scheme.

Maintenance exclusions have the following limitations:

- You can restrict the scope of automatic upgrades in a maintenance exclusion only for clusters that are enrolled in a release channel.

- You can add a maximum of 3 maintenance exclusions that exclude all upgrades (that is, a scope of "no upgrades").

- You can have a maximum of 20 maintenance exclusions in total.

- If you do not specify a scope in your exclusion, the scope defaults to "no upgrades".

## Configure a maintenance exclusion for an existing cluster
- To create a maintenance exclusion for existing-cluster for Black Friday, run the following command:
```
gcloud container clusters update existing-cluster \
--add-maintenance-exclusion-name black-friday \
--add-maintenance-exclusion-start 2022-11-23T00:00:00-06:00 \
--add-maintenance-exclusion-end 2022-11-26T23:59:59-06:00 \
--add-maintenance-exclusion-scope no_upgrades \
--zone us-central1-a
```
**Flags**
1. --add-maintenance-exclusion-name : the name of the maintenance exclusion.
2. --add-maintenance-exclusion-start : the start date and time for the exclusion.
3. --add-maintenance-exclusion-end : the end date and time for the exclusion.
4. --add-maintenance-exclusion-scope : the scope of upgrade to exclude, which can be one of the following values: no_upgrades, no_minor_upgrades, or no_minor_or_node_upgrades.

To view supported date and time formats, run gcloud topic datetimes.

- Verify existing-cluster has the maintenance exclusion configured
```
gcloud container clusters describe existing-cluster \
--zone=us-central1-a | grep -A 4 maintenanceExclusions
```
- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > existing-cluster or run the following command and click on the URL
```
echo -e "\nexisting-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/existing-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```
In the Automation section there is a Maintenance exclusions entry that shows the configured settings

## Remove a maintenance exclusion
- To remove the existing maintenance exclusion on existing-cluster for Black Friday, run the following command:
```
gcloud container clusters update existing-cluster \
--remove-maintenance-exclusion black-friday \
--zone us-central1-a
```
- Verify existing-cluster has the maintenance exclusion has been removed
```
gcloud container clusters describe existing-cluster \
--zone=us-central1-a | grep -A 4 maintenanceExclusions
```                 
- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > existing-cluster or run the following command and click on the URL
```
echo -e "\nexisting-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/existing-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```
In the Automation section there is a Maintenance exclusions entry that shows the settings are removed.

