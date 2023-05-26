# Introduction to Config Sync
Config Sync is a GitOps service built on an open source core that lets cluster operators and platform administrators deploy configurations from Git, OCI, or Helm repositories. The service has the flexibility to support one or many clusters and any number of repositories per cluster or namespace. The clusters can be in a hybrid or multi-cloud environment.

## Provisioning lab resources

### Preprovisioned resources
Two GKE clusters with GKE Workload Identity enabled have been preprovisioned and registered to the fleet with fleet Workload Identity enabled for this lab

 - cluster-000
 - cluster-001

You can describe each cluster

```
gcloud container clusters describe cluster-000 \
--zone us-central1-a
```
```
gcloud container clusters describe cluster-001 \
--zone us-central1-a
```
You can also see the clusters on the **Kubernetes Engine** -> **Overview** page of the console, run the following command to output a URL for the console.

```
echo -e "\nKubernetes Engine Clusters: https://console.cloud.google.com/kubernetes/list/overview?project=${GOOGLE_CLOUD_PROJECT}\n"
```
## Config Sync

GitOps is considered a universal best practice for organizations managing Kubernetes configuration as scale. The benefits of improved stability, better readability, consistency, audit and security are common to all GitOps tools. Config Sync is a service which provides you with a set of unique advantages:

Integrated: platform admins can install Config Sync using a few clicks in the Google Cloud console, using Terraform, or by using Google Cloud CLI on any cluster connected to your fleet. The service is pre-configured to work with other Google Cloud services like Policy Controller, Workload Identity and Cloud Monitoring.

Built-in observability: Config Sync has an observability dashboard that is built into the Google Cloud console, requiring no additional setup. Platform administrators can view the state of their synchronization and reconciliation by visiting the Google Cloud console or by using the Google Cloud CLI.

Multi-cloud and hybrid support: Config Sync is tested across several cloud providers and in hybrid environments prior to every GA release. To view the support matrix, see Version and upgrade support.

### Prerequisites
In order to use Config Sync with a GKE cluster on Google Cloud, you may need to do one or more of the following before prerequisites.

The preprovisioned resources in this lab have already had these prerequisites completed.
**GKE Workload Identity**

We recommend using GKE Workload Identity and subsequently fleet Workload Identity to manage authentication to the Google Cloud APIs. It is also possible to use a service account, but that approach is not covered in this lab.

GKE creates a fixed workload identity pool for each Google Cloud project, with the format `PROJECT_ID.svc.id.goog.`

 - Check if GKE Workload Identity is enabled

```
gcloud container clusters describe cluster-000 \
--format="value(workloadIdentityConfig)" \
--zone us-central1-a
```

`cluster-000` already has GKE Workload Identity enabled

`workloadPool=qwiklabs-gcp-##-############.svc.id.goog`

```
gcloud container clusters describe cluster-001 \
--format="value(workloadIdentityConfig)" \
--zone us-central1-a
```
`cluster-001` already has GKE Workload Identity enabled

`workloadPool=qwiklabs-gcp-##-############.svc.id.goog`

 - How to enable GKE Workload Identity if it is **NOT** enabled

  `You can enable GKE Workload Identity on an existing Standard cluster by using the gcloud CLI or the Google Cloud console. Existing node pools are unaffected, but any new node pools in the cluster use GKE Workload Identity by default.`

```
gcloud container clusters update cluster-000 \
--workload-pool=${GOOGLE_CLOUD_PROJECT}.svc.id.goog \
--zone us-central1-a
```

`Updating cluster-000..working...done.
Updated [https://container.googleapis.com/v1/projects/qwiklabs-gcp-##-############/zones/us-central1-a/clusters/cluster-000].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1-a/cluster-000?project=qwiklabs-gcp-##-############`

**Caution**: Modifying a node pool immediately enables GKE Workload Identity for any workloads running in the node pool. This prevents the workloads from using the Compute Engine default service account and might result in disruptions. You can selectively disable GKE Workload Identity on a specific node pool by explicitly specifying --workload-metadata=GCE_METADATA. See Protecting cluster metadata for more information

```
gcloud container node-pools update default-pool \
--cluster=cluster-000 \
--workload-metadata=GKE_METADATA \
--zone us-central1-a
```

`Updating node pool default-pool... Updating default-pool, done with 2 out of 2 nodes (100.0%): 2 succeeded...done.
Updated [https://container.googleapis.com/v1/projects/qwiklabs-gcp-##-############/zones/us-central1-a/clusters/cluster-000/nodePools/default-pool].`

**IAM**

For GKE clusters, add the following IAM role to get admin permissions on the cluster, if you don't have it already (your user account is likely to have it if you created the cluster):

 - `roles/container.admin`

This IAM role includes the Kubernetes RBAC cluster-admin role. For other cluster environments you need to grant this RBAC role using kubectl, as described in the next section. You can find out more about the relationship between IAM and RBAC roles in GKE in the GKE documentation.

**Register clusters to the Fleet Host Project**

The implementation of fleets, like many other Google Cloud resources, is rooted in a Google Cloud project, which we refer to as the fleet host project. A given Cloud project can only have a single fleet (or no fleets) associated with it. This restriction reinforces using Cloud projects to provide stronger isolation between resources that are not governed or consumed together.

For this lab the fleet host project is the same project where the clusters were created.

 - Verify the fleet memberships
  
```
gcloud container fleet memberships list
```

`NAME: cluster-000
EXTERNAL_ID: ########-####-####-####-############
LOCATION: global`

`NAME: cluster-001
EXTERNAL_ID: ########-####-####-####-############
LOCATION: global`

 - How to register a cluster if it is **NOT** registered

Enable the `gkehub.googleapis.com` APIs

```
gcloud services enable gkehub.googleapis.com
```

`Operation "operations/####.##-############-########-####-####-####-############" finished successfully.`

 - Register the cluster

`It is recommended to registering the GKE clusters with fleet Workload Identity enabled. This provides a consistent way for applications to authenticate to Google Cloud APIs and services. You can find out more about the advantages of enabling fleet Workload Identity in Use fleet Workload Identity.`

```
gcloud container fleet memberships register cluster-000 \
--gke-cluster=us-central1-a/cluster-000 \
--enable-workload-identity
```
`Waiting for membership to be created...done.
Finished registering to the Fleet.`

## Install Config Sync

For this lab we will install Config Sync and configure it to use the configs in the config-sync-quickstart directory of the GoogleCloudPlatform/anthos-config-management-samples repository.

 - Enable the Config Management Feature

```
gcloud beta container hub config-management enable
```


`Enabling service [anthosconfigmanagement.googleapis.com] on project [qwiklabs-###-##-############]...
Operation "operations/####.##-############-########-####-####-####-############" finished successfully.
Waiting for service API enablement to finish...
Waiting for Feature Config Management to be created...done.`

 - Create a new `apply-spec.yaml` manifest

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

For all of the available fields, see the Configuration for Config Sync section in gcloud apply spec fields

 - Apply the `apply-spec.yaml` file to each cluster

```
gcloud beta container fleet config-management apply \
--membership=cluster-000 \
--config=${HOME}/config-sync/apply-spec.yaml
```

`Waiting for Feature Config Management to be updated...done.`

```
gcloud beta container fleet config-management apply \
--membership=cluster-001 \
--config=${HOME}/config-sync/apply-spec.yaml
```
`Waiting for Feature Config Management to be updated...done.`

 - Verify the status of the installation

```
gcloud beta container hub config-management status
```

When the installation has completed successfully the `Status` will be `SYNCED`.

`Name: global/cluster-000
Status: SYNCED
Last_Synced_Token: #######
Sync_Branch: main
Last_Synced_Time: YYYY-MM-DDTHH:MM:SSZ
Policy_Controller: GatekeeperControllerManager NOT_INSTALLED
Hierarchy_Controller: PENDING`

`Name: global/cluster-001
Status: SYNCED
Last_Synced_Token: #######
Sync_Branch: main
Last_Synced_Time: YYYY-MM-DDTHH:MM:SSZ
Policy_Controller: GatekeeperControllerManager NOT_INSTALLED
Hierarchy_Controller: PENDING`

You can also see the status on the **Kubernetes Engine** -> **Config** page of the console, run the following command to output a URL for the console.

```
echo -e "\nConfig Management UI: https://console.cloud.google.com/kubernetes/config_management?project=${GOOGLE_CLOUD_PROJECT}\n"
```

##Explore Config Sync

 - Get cluster credentials

```
gcloud container clusters get-credentials cluster-000 \
--zone us-central1-a
```

`Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-000.`

 - List the managed namespaces

All objects managed by Config Sync have the `app.kubernetes.io/`managed-by label set to `configmanagement.gke.io`.

```
kubectl get namespaces --selector app.kubernetes.io/managed-by=configmanagement.gke.io
```

`NAME         STATUS   AGE
gamestore    Active   ##m##s
monitoring   Active   ##m##s`

 - Delete the managed gamestore namespace

```
kubectl delete namespace gamestore
```

`namespace "gamestore" deleted`

 - List the managed namespaces

```
kubectl get namespaces --selector app.kubernetes.io/managed-by=configmanagement.gke.io
```

See that the gamestore namespace was recreated.

`NAME         STATUS   AGE
gamestore    Active   ##s
monitoring   Active   ##m##s`

You can explore the config-sync-quickstart repository to see what other resources are created and managed.
