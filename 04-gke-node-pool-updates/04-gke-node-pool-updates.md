# Updating node labels and taints
Node taints and labels are in the object metadata of Kubernetes nodes. Labels are used to schedule Pods on particular nodes, where taints can be used to steer Pods away from them.

Using the Kubernetes Engine API, you can apply updates on the node labels, and node taints of an existing GKE node pool without needing to recreate the node pool or disrupt running workloads. The updated node pool configuration is preserved in GKE, so that future node pool upgrades and new node provisions in the node pool will use the new configuration.

## Limitations
There are some limitations for using the Kubernetes Engine API to dynamically update node pool configurations:

The version for the node pool must be 1.19.7-gke.1500 or later.

The version for the cluster's control plane must be 1.23.4-gke.300 or later to apply updates to node labels or node taints for existing node pools with cluster autoscaler enabled. For clusters on earlier versions, you can use the following workaround: Disable autoscaling on the node pool, and then update the node labels and/or taints. After the updates have been applied, re-enable autoscaling.

# Updating node labels
- Get credentials for existing-cluster
```
gcloud container clusters get-credentials existing-cluster \
--zone=us-central1-a
```
- Verify the label1 label does not exist
```
kubectl get nodes --show-labels | grep label1=value1
```     
- Update node labels for the default-pool node pool
```
gcloud container node-pools update default-pool \
--node-labels=label1=value1 \
--cluster=existing-cluster \
--zone=us-central1-a
```
> Warning: This update overwrites any previous user-specified values.
- Verify the label1 label exist
```
kubectl get nodes --show-labels | grep label1=value1
```
# Updating node taints
- Get credentials for existing-cluster
```
gcloud container clusters get-credentials existing-cluster \
--zone=us-central1-a
```
- Verify the key1 taint does not exist
```
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
- Update node taints for the default-pool node pool
```
gcloud container node-pools update default-pool \
--node-taints=key1=val1:NoSchedule \
--cluster=existing-cluster \
--zone=us-central1-a
```
> Warning: This update can overwrite any previous user-specified values on individual nodes during node upgrade and recreation.

- Verify the key1 taint exist
```
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
# Changing machine type
When you need to change the machine profile of your Compute Engine cluster, you can create a new node pool and then migrate your workloads over to the new node pool.

To migrate your workloads without incurring downtime, you need to:

- Create a new node pool.
- Mark the existing node pool as unschedulable.
- Drain the workloads running on the existing node pool.
- Delete the existing node pool.
Kubernetes, which is the cluster orchestration system of GKE clusters, automatically reschedules the evicted Pods to the new node pool as it drains the existing node pool.

- Create the new-pool node pool
```
gcloud container node-pools create new-pool \
--cluster=existing-cluster \
--machine-type=e2-standard-2 \
--num-nodes=3 \
--disk-size=50GB \
--zone=us-central1-a
```
- List the node pools for the cluster
```
gcloud container node-pools list \
--cluster existing-cluster \
--zone=us-central1-a
```
- Get credentials for existing-cluster
```
gcloud container clusters get-credentials existing-cluster \
--zone=us-central1-a
```
- Verify the pods are running on the on the default-pool node pool
```
kubectl --namespace=boa get pods --output=wide
```
- Cordon the existing default-pool node pool

**Note: If your workload has a LoadBalancer service with externalTrafficPolicy set to Local, then cordoning the existing node pool might cause the workload to become unreachable. Either change the externalTrafficPolicy to Cluster or ensure the workload is re-deployed into the new node pool before cordoning the existing pool.**
```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl cordon "$node";
done
```
- Drain the existing node pool

**Note: Kubernetes does not reschedule Pods that are not managed by a controller such as Deployment, ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet. Such Pods prevent kubectl drain commands from running, therefore you must deploy your Pods using these controllers. For this lab, run kubectl drain with --force option to clean up some GKE system Pods.**
```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
  kubectl drain --force --ignore-daemonsets --delete-emptydir-data "$node";
done
```
- Verify the pods are running on the on the new-pool node pool
```
kubectl --namespace=boa get pods --output=wide
```
- Delete the existing node pool
```
gcloud container node-pools delete default-pool \
--cluster existing-cluster \
--zone=us-central1-a
```
