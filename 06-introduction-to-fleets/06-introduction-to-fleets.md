# Introduction to Fleets

If you need to work with multiple GKE clusters, fleets provides an extra layer of tools and features that can help you manage, govern, and operate containerized workloads at scale. Google Cloud offers a set of capabilities that helps you and your organization (from infrastructure operators and workload developers to security and network engineers) manage clusters, infrastructure, and workloads, on Google Cloud and across public cloud and on-premises environments. These capabilities are all built around the idea of the fleet: a logical grouping of Kubernetes clusters and other resources that can be managed together. Fleets are managed by the Fleet service, also known as the Hub service.

## Preprovisioned resources

Two GKE clusters have been preprovisioned for this lab

 - `cluster-000`
 - `cluster-001`

You can describe each cluster
```
gcloud container clusters describe cluster-000 \
--zone us-central1-a
```
```
gcloud container clusters describe cluster-001 \
--zone us-central1-a
```
## Fleets

Typically, as organizations embrace cloud-native technologies like containers, container orchestration, and service mesh, they reach a point where running a single cluster is no longer sufficient. There are a variety of reasons why organizations choose to deploy multiple clusters to achieve their technical and business objectives; for example, separating production from non-production environments, or separating services across tiers, locales, or teams. You can read more about the benefits and tradeoffs involved in multi-cluster approaches in multi-cluster use cases.

Google Cloud use the concept of a fleet to simplify managing multi-cluster deployments. A fleet provides a way to logically group and normalize Kubernetes clusters, making administration of infrastructure easier. A fleet can be entirely made up of Google Kubernetes Engine clusters on Google Cloud, or include clusters outside Google Cloud. A growing number of Google Cloud components use fleet concepts such as identity sameness and namespace sameness to simplify working with multiple clusters.

Adopting fleets helps your organization uplevel management from individual clusters to entire groups of clusters. Furthermore, the normalization that fleets require can help your teams adopt similar best practices to those used at Google.

 - To learn more about how fleets work, and to find a complete list of fleet-enabled features, see How fleets work.

 - To learn about current limitations and requirements for using fleets in multi-cluster deployments, as well as recommendations for implementing fleets in your organization, see Fleet requirements and best practices.

### Prerequisites

If you are registering a GKE cluster on Google Cloud, you may need to do one or more of the following before registering the cluster, depending on the registration option you choose.

**GKE Workload Identity**

We recommend using GKE Workload Identity and subsequently fleet Workload Identity to manage authentication to the Google Cloud APIs. It is also possible to use a service account, but that approach is not covered in this lab.

GKE creates a fixed workload identity pool for each Google Cloud project, with the format PROJECT_ID.svc.id.goog.

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

`cluster-001` does not have GKE Workload Identity enabled
        
 - Enable GKE Workload Identity on `cluster-001`

You can enable GKE Workload Identity on an existing Standard cluster by using the gcloud CLI or the Google Cloud console. Existing node pools are unaffected, but any new node pools in the cluster use GKE Workload Identity by default.
```
gcloud container clusters update cluster-001 \
--workload-pool=${GOOGLE_CLOUD_PROJECT}.svc.id.goog \
--zone us-central1-a
```
`Updating cluster-001...working...done.
Updated [https://container.googleapis.com/v1/projects/qwiklabs-gcp-##-############/zones/us-central1-a/clusters/cluster-001].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1-a/cluster-001?project=qwiklabs-gcp-##-############`

**Caution***: Modifying a node pool immediately enables GKE Workload Identity for any workloads running in the node pool. This prevents the workloads from using the Compute Engine default service account and might result in disruptions. You can selectively disable GKE Workload Identity on a specific node pool by explicitly specifying --workload-metadata=GCE_METADATA. See Protecting cluster metadata for more information
```
gcloud container node-pools update default-pool \
--cluster=cluster-001 \
--workload-metadata=GKE_METADATA \
--zone us-central1-a
```
`Updating node pool default-pool... Updating default-pool, done with 2 out of 2 nodes (100.0%): 2 succeeded...done.
Updated [https://container.googleapis.com/v1/projects/qwiklabs-gcp-##-############/zones/us-central1-a/clusters/cluster-001/nodePools/default-pool].`

**IAM**

For GKE clusters, add the following IAM role to get admin permissions on the cluster, if you don't have it already (your user account is likely to have it if you created the cluster):

 - `roles/container.admin`

This IAM role includes the Kubernetes RBAC cluster-admin role. For other cluster environments you need to grant this RBAC role using kubectl, as described in the next section. You can find out more about the relationship between IAM and RBAC roles in GKE in the GKE documentation.

**Fleet Host Project**

The implementation of fleets, like many other Google Cloud resources, is rooted in a Google Cloud project, which we refer to as the fleet host project. A given Cloud project can only have a single fleet (or no fleets) associated with it. This restriction reinforces using Cloud projects to provide stronger isolation between resources that are not governed or consumed together.

## Create a fleet

Creating a fleet involves registering the clusters you want to manage together to a fleet in your chosen fleet host project. Depending on the cluster type and where it lives, registration can happen automatically at cluster creation time with registration details specified in the cluster configuration, or you may need to manually add the cluster to your fleet.

For this lab the fleet host project is the same project where the clusters were created.

 - Enable the gkehub.googleapis.com APIs

```
gcloud services enable gkehub.googleapis.com
```
`Operation "operations/####.##-############-########-####-####-####-############" finished successfully.`

 - Register the clusters

As recommended above, we will registering the GKE clusters with fleet Workload Identity enabled. This provides a consistent way for applications to authenticate to Google Cloud APIs and services. You can find out more about the advantages of enabling fleet Workload Identity in Use fleet Workload Identity.

```
gcloud container fleet memberships register cluster-000 \
--gke-cluster=us-central1-a/cluster-000 \
--enable-workload-identity
```

`Waiting for membership to be created...done. Finished registering to the Fleet.`

```
gcloud container fleet memberships register cluster-001 \
--gke-cluster=us-central1-a/cluster-001 \
--enable-workload-identity
```

`Waiting for membership to be created...done. Finished registering to the Fleet.`

 - Verify the fleet memberships

```
gcloud container fleet memberships list
```

`NAME: cluster-000
EXTERNAL_ID: ########-####-####-####-############
LOCATION: global
NAME: cluster-001
EXTERNAL_ID: ########-####-####-####-############
LOCATION: global`
