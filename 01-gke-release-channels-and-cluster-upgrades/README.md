# GKE release channels and cluster upgrades challenge lab

## Overview

By default, auto-upgrading nodes are enabled for Google Kubernetes Engine (GKE) clusters and node pools.

GKE release channels offer you the ability to balance between stability and feature set of the version deployed in the cluster. When you enroll a new cluster in a release channel, Google automatically manages the version and upgrade cadence for the cluster and its node pools.

## Enrolling Clusters in Release Channels

### Enroll an existing clusters

1. Create a GKE cluster called `prod-cluster`
2. Enroll `prod-cluster` in the stable release channel
3. Verify `prod-cluster` is enrolled in the stable release channel
4. Create `dev-cluster` and enroll it in the regular release channel
5. Verify dev-cluster is enrolled in the regular release channel

**Docs:**

- [Create GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)
- [Update GKE Cluster Release Channel](https://cloud.google.com/sdk/gcloud/reference/container/clusters/update#--release-channel)
- [Verify GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/describe)

## Checking node pool upgrade status

1. List every running and completed operation in the cluster
2. Get information about a specific operation, describe the specific operation name

**Docs:**

- [Verify GKE Cluster Operations](https://cloud.google.com/sdk/gcloud/reference/beta/container/operations)

## Rolling back a node pool upgrade

You can roll back node pools that failed to upgrade, or whose upgrades were canceled, to their previous version of Kubernetes. You cannot roll back node pools once they have been successfully upgraded. Nodes that have not started an upgrade are unaffected.

1. Rollback the default node pool on the `dev-cluster`

**Docs:**

- [Node Pool Rollback](https://cloud.google.com/kubernetes-engine/docs/how-to/upgrading-a-cluster#rollback)

## Changing the release channel

Migrating between release channels is supported in limited scenarios.

- A transition that results in a single minor version upgrade, such as migrating from Stable to Regular, is supported.
- Downgrades, such as migrating from Regular to Stable, are not possible due to the risk in downgrading across Kubernetes minor versions. Similarly, upgrades of more than a single minor version, such as migrating from Stable to Rapid, are not supported.
- To select a new release channel, update the cluster release channel to the desired CHANNEL.
- In cases where selecting a new release channel is not supported, we encourage you to create a new cluster in the desired channel and migrate your workloads. If you'd prefer to use your existing cluster, you can follow the instructions for unsubscribing from a release channel, wait for the target release channel to make available the Kubernetes minor version of your cluster, and then follow the instructions to enroll the existing cluster in the target release channel.

1. Change `prod-cluster` to the regular release channel
2. Verify prod-cluster is enrolled to the regular release channel

**Docs:**

- [Update GKE Cluster Release Channel](https://cloud.google.com/sdk/gcloud/reference/container/clusters/update#--release-channel)
- [Verify GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/describe)

## Unsubscribing from release channels

If you choose to unsubscribe from a channel, the node pools for the cluster will continue to have auto-upgrade and auto-repair enabled, even after disabling release channels. Once a cluster is no longer subscribed to a release channel, you can disable node auto-upgrade and disable node auto-repair manually.

When a cluster is unsubscribed from a release channel, manual upgrades are still subject to the following limitations:

- You can only upgrade to versions that are available.
- You cannot upgrade more than one minor version at a time.
- You cannot downgrade a minor version.

**NOTE: Autopilot clusters cannot be unsubscribed from a release channel.**

1. Unsubscribe the `dev-cluster` from release channels
2. Verify the `dev-cluster` is no longer subscribed to a release channel

## Manually upgrading a cluster

### Manually upgrade the control plane

When initiating a cluster upgrade, you can't modify the cluster's configuration for several minutes, until the control plane is accessible again. If you need to prevent downtime during control plane upgrades, consider using a regional cluster.

After upgrading your cluster, you can upgrade its nodes. By default, nodes created using the Google Cloud Console have auto-upgrade enabled, so this so this happens automatically.

Note: You cannot upgrade your cluster more than one minor version at a time. For example, you can upgrade a cluster from version 1.21.x to 1.22.x, but not directly from 1.20.x to 1.22.x. For more information, refer to Versioning.

1. Get a list of available versions for your `dev-cluster's` control plane
2. Upgrade the `dev-cluster` to the default cluster version
3. Upgrade, or downgrade the `dev-cluster` to a specific version

**Docs:**

- [GKE Server Config](https://cloud.google.com/sdk/gcloud/reference/container/get-server-config)
- [Upgrade Existing GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/upgrade)

### Manually upgrade the node pool(s)

You can manually upgrade a node pool version to match the version of the control plane or to a previous version that is still available and is compatible with the control plane. The Kubernetes version and version skew support policy guarantees that control planes are compatible with nodes up to two minor versions older than the control plane.

When you manually upgrade a node pool, GKE removes any labels you added to individual nodes. To avoid this, apply labels to node pools instead.

Upgrading a node pool may disrupt workloads running in that node pool. To avoid this, you can create a new node pool with the desired version and migrate the workload. After migration, you can delete the old node pool.

1. Upgrade an existing node pool
2. Upgrade all nodes to the same version as the control plane
3. Upgrade, or downgrade the `dev-cluster` to a specific version by specifying the --cluster-version
4. Upgrade a specific `dev-cluster` node pool, by specifying the --node-pool flag

**Docs:**

- [Upgrade Existing GKE Clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters/upgrade)

### Upgrade by creating and migrating to a new node pool

1. Create new node pool on the `dev-cluster` called `new-pool`
2. List the node pools for the `dev-cluster`
3. Get credentials for the `dev-cluster`
4. Cordon the existing `default-pool` node pool
5. Drain the existing `default-pool` node pool
6. Delete the existing `default-pool` node pool for the `dev-cluster`

**Docs:**

- [Manage GKE Node Pool](https://cloud.google.com/sdk/gcloud/reference/container/node-pools)
- [Get GKE Credentials](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)
- [Cordon and Drain Node Pools](https://cloud.google.com/kubernetes-engine/docs/tutorials/migrating-node-pool#step_4_migrate_the_workloads)
