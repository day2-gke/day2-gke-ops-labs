# GKE release channels and cluster upgrades

## Overview

By default, auto-upgrading nodes are enabled for Google Kubernetes Engine (GKE) clusters and node pools.

GKE release channels offer you the ability to balance between stability and feature set of the version deployed in the cluster. When you enroll a new cluster in a release channel, Google automatically manages the version and upgrade cadence for the cluster and its node pools.

### Enrolling a cluster in a release channel

You can enroll a new or existing cluster in a release channel.

#### Enroll an existing clusters

- Enroll prod-cluster in the stable release channel

```
gcloud container clusters create prod-cluster \
--enable-ip-alias \
--network=gke-day2-ops \
--subnetwork=gke-primary \
--cluster-secondary-range-name=gke-pods \
--services-secondary-range-name=gke-services \
--release-channel=stable \
--zone=europe-west2-a
```

- Verify prod-cluster is enrolled in the stable release channel

```
gcloud container clusters create dev-cluster \
--enable-ip-alias \
--network=gke-day2-ops \
--subnetwork=gke-primary \
--cluster-secondary-range-name=gke-pods \
--services-secondary-range-name=gke-services \
--release-channel=stable \
--zone=europe-west2-a
```

#### Enroll a clusters when creating

Create dev-cluster and enroll it in the regular release channel

```
gcloud container clusters create dev-cluster \
--num-nodes=1 \
--release-channel=regular \
--zone=us-central1-a
```

as the regular release channel is the default, the following command also enrolls the cluster in the regular release channel

```
gcloud container clusters create dev-cluster \
--num-nodes=1 \
--zone=us-central1-a
```

- Verify dev-cluster is enrolled in the regular release channel

```
gcloud container clusters describe dev-cluster \
--format="value(releaseChannel.channel)" \
--zone=us-central1-a
```

### Checking node pool upgrade status

- List every running and completed operation in the cluster

```
gcloud beta container operations list \
--zone=us-central1-a
```

- For more information about a specific operation, describe the specific operation name

```
gcloud beta container operations describe OPERATION_NAME \
--zone=us-central1-a
```

### Rolling back a node pool upgrade

You can roll back node pools that failed to upgrade, or whose upgrades were canceled, to their previous version of Kubernetes. You cannot roll back node pools once they have been successfully upgraded. Nodes that have not started an upgrade are unaffected.

```
gcloud container node-pools rollback default-pool \
--cluster dev-cluster \
--zone=us-central1-a
```

### Changing the release channel

Migrating between release channels is supported in limited scenarios.

A transition that results in a single minor version upgrade, such as migrating from Stable to Regular, is supported.

Downgrades, such as migrating from Regular to Stable, are not possible due to the risk in downgrading across Kubernetes minor versions. Similarly, upgrades of more than a single minor version, such as migrating from Stable to Rapid, are not supported.

To select a new release channel, update the cluster release channel to the desired CHANNEL.

In cases where selecting a new release channel is not supported, we encourage you to create a new cluster in the desired channel and migrate your workloads. If you'd prefer to use your existing cluster, you can follow the instructions for unsubscribing from a release channel, wait for the target release channel to make available the Kubernetes minor version of your cluster, and then follow the instructions to enroll the existing cluster in the target release channel.

- Change prod-cluster to the regular release channel

```
gcloud container clusters update prod-cluster \
--release-channel=regular \
--zone=us-central1-a
```

- Verify prod-cluster is enrolled to the regular release channel

```
gcloud container clusters describe prod-cluster \
--format="value(releaseChannel.channel)" \
--zone=us-central1-a
```

### Unsubscribing from release channels

If you choose to unsubscribe from a channel, the node pools for the cluster will continue to have auto-upgrade and auto-repair enabled, even after disabling release channels. Once a cluster is no longer subscribed to a release channel, you can disable node auto-upgrade and disable node auto-repair manually.

When a cluster is unsubscribed from a release channel, manual upgrades are still subject to the following limitations:

You can only upgrade to versions that are available.
You cannot upgrade more than one minor version at a time.
You cannot downgrade a minor version.

_NOTE: Autopilot clusters cannot be unsubscribed from a release channel._

- Unsubscribe the dev-cluster from release channels

```
gcloud container clusters update dev-cluster \
--release-channel=None \
--zone=us-central1-a
```

- Verify the dev-cluster is no longer subscribed to a release channel

```
gcloud container clusters describe dev-cluster \
--format="value(releaseChannel.channel)" \
--zone=us-central1-a
```

### Manually upgrading a cluster

#### Manually upgrade the control plane

When initiating a cluster upgrade, you can't modify the cluster's configuration for several minutes, until the control plane is accessible again. If you need to prevent downtime during control plane upgrades, consider using a regional cluster.

After upgrading your cluster, you can upgrade its nodes. By default, nodes created using the Google Cloud Console have auto-upgrade enabled, so this so this happens automatically.

Note: You cannot upgrade your cluster more than one minor version at a time. For example, you can upgrade a cluster from version 1.21.x to 1.22.x, but not directly from 1.20.x to 1.22.x. For more information, refer to Versioning.

- Get a list of available versions for your cluster's control plane

```
gcloud container get-server-config \
--zone=us-central1-a
```

- Upgrade to the default cluster version

```
gcloud container clusters upgrade dev-cluster \
--master \
--zone=us-central1-a
```

- To upgrade, or downgrade, to a specific version

```
gcloud container clusters upgrade dev-cluster \
--cluster-version=<GKE_VERSION> \
--master \
--zone=us-central1-a
```

#### Manually upgrade the node pool(s)

You can manually upgrade a node pool version to match the version of the control plane or to a previous version that is still available and is compatible with the control plane. The Kubernetes version and version skew support policy guarantees that control planes are compatible with nodes up to two minor versions older than the control plane.

When you manually upgrade a node pool, GKE removes any labels you added to individual nodes. To avoid this, apply labels to node pools instead.

Upgrading a node pool may disrupt workloads running in that node pool. To avoid this, you can create a new node pool with the desired version and migrate the workload. After migration, you can delete the old node pool.

- Upgrade an existing node pool \*

* Upgrade all nodes to the same version as the control plane

```
gcloud container clusters upgrade dev-cluster \
--zone=us-central1-a
```

- Upgrade, or downgrade, to a specific version by specifying the --cluster-version

```
gcloud container clusters upgrade dev-cluster \
--cluster-version=<GKE_VERSION> \
--zone=us-central1-a
```

- Upgrade a specific node pool, by specifying the --node-pool flag

```
gcloud container clusters upgrade dev-cluster \
--node-pool=default-pool \
--zone=us-central1-a
```

_Upgrade by creating and migrating to a new node pool_

- Create new node pool

```
gcloud container node-pools create new-pool \
--cluster=dev-cluster \
--num-nodes=1 \
--zone=us-central1-a
```

- List the node pools for the cluster

```
gcloud container node-pools list \
--cluster dev-cluster \
--zone=us-central1-a
```

- Get credentials for the cluster

```
gcloud container clusters get-credentials dev-cluster \
--zone=us-central1-a
```

- Cordon the existing node pool

```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl cordon "$node";
done
```

- Drain the existing node pool

```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
  kubectl drain --force --ignore-daemonsets --delete-emptydir-data --grace-period=10 "$node";
done
```

- Delete the existing node pool

```
gcloud container node-pools delete default-pool \
--cluster dev-cluster \
--zone=us-central1-a
```
