# Overview
Policy Controller enables the enforcement of fully programmable policies for your clusters. These policies act as "guardrails" and prevent any changes to the configuration of the Kubernetes API from violating security, operational, or compliance controls.

Policy Controller enforces policies by using constraints and constraint templates. It is based on the open source Open Policy Agent Gatekeeper project and comes with a full library of pre-built policies for common security and compliance controls.

## What you'll learn
- In this lab, you will learn how to:
- Try out Policy Controller
- Install Policy Controller
- Review the constraint templates in the default template library
- Define a constraint
- Fix violations
- Remove a constraint
- Use Policy Controller metrics
- Troubleshoot Policy Controller

## Prerequisites
A working knowledge of the following technologies is beneficial, but not required for this lab:

- Cloud Shell and the gcloud CLI
- Google Kubernetes Engine (GKE)
- Anthos Config Management (ACM)
- Policy Controller
- Open Policy Agent (OPA) Gatekeeper

Try Policy Controller
You can create a trial report of Policy Controller in the Google Cloud console to audit your Anthos or GKE clusters. This trial lets you audit a cluster against the Policy Essentials bundle, a set of baseline policies based on Google-recommended best practices. You can then view any policy violations in a dashboard in the Google Cloud console.

The trial does not install Policy Controller on your clusters and does not incur any billing charges. You can install Policy Controller to leverage more capabilities such as policy enforcement at CI/CD or admission time, continuous auditing of clusters, and access to the full constraint template library, which you can use to apply constraints to enforce policies without writing custom constraints.

For step-by-step guidance for this task directly in the Google Cloud console, right click on Guide me and click Open link in incognito window

Guide me

Or you can follow the instructions at Try Policy Controller

Install Policy Controller
Enable the GKE Hub APIs

gcloud services enable gkehub.googleapis.com
Copied!
Operation "operations/####.##-############-########-####-####-####-############" finished successfully.
Register the cluster with the fleet

gcloud container fleet memberships register existing-cluster \
--gke-cluster=us-central1-a/existing-cluster \
--enable-workload-identity
Copied!
Waiting for membership to be created...done.
Finished registering to the Fleet.
Enable the Config Management Feature

gcloud beta container hub config-management enable
Copied!
Enabling service [anthosconfigmanagement.googleapis.com] on project [qwiklabs-###-##-############]...
Operation "operations/####.##-############-########-####-####-####-############" finished successfully.
Waiting for service API enablement to finish...
Waiting for Feature Config Management to be created...done.
Create the Anthos Config Management apply-spec.yaml configuration file for Policy Controller

cat <<EOF > apply-spec.yaml
applySpecVersion: 1
spec:
  policyController:
    # Set to true to install and enable Policy Controller
    enabled: true
    # Install the default template library
    templateLibraryInstalled: true
EOF
Copied!
For all of the available configuration values see the Configuration for Policy Controller gcloud apply spec fields documentation.
Apply the Anthos Config Management apply-spec.yaml configuration file for Policy Controller

gcloud beta container fleet config-management apply \
--membership=existing-cluster \
--config=apply-spec.yaml
Copied!
Waiting for Feature Config Management to be updated...done.
Verify the Policy Controller installation

gcloud beta container fleet config-management status
Copied!
While Policy Controller is being installed and initialized, Policy_Controller: can show various status messages:

Name: existing-cluster
Status: PENDING
Last_Synced_Token: NA
Sync_Branch: NA
Last_Synced_Time: NA
Policy_Controller: GatekeeperControllerManager NOT_INSTALLED
Hierarchy_Controller: PENDING
When the installation is complete, Policy_Controller: will be INSTALLED:

Name: existing-cluster
Status: PENDING
Last_Synced_Token: NA
Sync_Branch: NA
Last_Synced_Time: NA
Policy_Controller: INSTALLED
Hierarchy_Controller: PENDING
Constraint Templates
When you define a constraint, you specify the constraint template that it extends. A library of common constraint templates developed by Google is installed by default, and many organizations do not need to create custom constraint templates directly in Rego. Constraint templates provided by Google have the label configmanagement.gke.io/configmanagement.

Get credentials for existing-cluster

gcloud container clusters get-credentials existing-cluster \
--zone=us-central1-a
Copied!
Fetching cluster endpoint and auth data.
kubeconfig entry generated for existing-cluster.
List all Google provided constraints

kubectl get constrainttemplates \
-l="configmanagement.gke.io/configmanagement=config-management"
Copied!
To describe a constraint template and check its required parameters

kubectl describe constrainttemplate <CONSTRAINT_TEMPLATE_NAME>
Example

kubectl describe constrainttemplate k8srequiredlabels
Copied!
The constraint templates can also be viewed in the constraint template library
Define a constraint
You define a constraint by using YAML, and you do not need to understand or write Rego. Instead, a constraint invokes a constraint template and provides it with parameters specific to the constraint.

Constraints have the following fields:

The lowercased kind matches the name of a constraint template.

The metadata.name is the name of the constraint.

The match field defines which objects the constraint applies to. All conditions specified must be matched before an object is in-scope for a constraint. match conditions are defined by the following sub-fields:

kinds are the kinds of resources the constraint applies to, determined by two fields: apiGroups is a list of Kubernetes API groups that will match and kinds is a list of kinds that will match. "*" matches everything. If at least one apiGroup and one kind entry match, the kinds condition is satisfied.
scope accepts _, Cluster, or Namespaced, which determines if cluster-scoped and/or namespaced-scoped resources are selected (defaults to _).
namespaces is a list of namespace names the object can belong to. The object must belong to at least one of these namespaces. Namespace resources are treated as if they belong to themselves.
excludedNamespaces is a list of namespaces that the object cannot belong to.
labelSelector is a Kubernetes label selector that the object must satisfy.
namespaceSelector is a label selector on the namespace the object belongs to. If the namespace does not satisfy the object, it will not match. Namespace resources are treated as if they belong to themselves.
The parameters field defines the arguments for the constraint, based on what the constraint template expects.

Define a constraint

cat <<EOF > constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-team-label
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Namespace"]
  parameters:
    labels:
    - key: "team"
EOF
Copied!
Apply the constraint

kubectl apply -f constraint.yaml
Copied!
k8srequiredlabels.constraints.gatekeeper.sh/ns-must-have-team-label created
Get all constraints

kubectl get constraints
Copied!
NAME                                                                  ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8srequiredlabels.constraints.gatekeeper.sh/ns-must-have-team-label                        ##
Fix violations
Once the constraint is created it may take some time for the constraint check to execute. Once the check has execute, the constraint will show a numeric value for status.totalViolations.

You can audit the constraint using kubectl describe

kubectl describe k8srequiredlabels ns-must-have-team-label
Copied!
If the constraint is configured and installed correctly, its status.byPod[].enforced field is set to true, whether the constraint is configured to enforce or only test the constraint.

Constraints are enforced by default, and a violation of a constraint prevents a given cluster operation. You can set a constraint's spec.enforcementAction to dryrun to report violations in the status.violations field without preventing the operation.

Fix the violations

There are several existing namespaces that violating the constraint, they are listed under status.violations. Add the team label to fix the violations

kubectl label namespace config-management-monitoring team=platform-ops
kubectl label namespace config-management-system team=platform-ops
kubectl label namespace default team=platform-ops
kubectl label namespace gatekeeper-system team=platform-ops
kubectl label namespace kube-node-lease team=platform-ops
kubectl label namespace kube-public team=platform-ops
kubectl label namespace kube-system team=platform-ops
Copied!
namespace/config-management-monitoring labeled
namespace/config-management-system labeled
namespace/default labeled
namespace/gatekeeper-system labeled
namespace/kube-node-lease labeled
namespace/kube-public labeled
namespace/kube-system labeled
Audit the constraint

kubectl describe k8srequiredlabels ns-must-have-team-label
Copied!
Name:         ns-must-have-team-label
Namespace:
Labels:       <none>
Annotations:  <none>
API Version:  constraints.gatekeeper.sh/v1beta1
Kind:         K8sRequiredLabels
Metadata:
...
Total Violations:  0
Events:            <none>
status.totalViolations should now be 0

- Test the constraint with a new namespaces
```
kubectl create namespace app-team-a
```
- Create a new namespace that satisfies the constraint

```
cat <<EOF > ns-app-team-a.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: app-team-a
  labels:
    team: app-team-a
EOF
```
```
kubectl apply -f ns-app-team-a.yaml
```

# Remove a constraint
To remove a constraint, you must specify its kind and name.

You can find all constraints that use a constraint template by list all objects with the same kind as the constraint template's metadata.name

- List all constraints that use the k8srequiredlabels constraint template
```
kubectl get k8srequiredlabels
```
- deleted the constraint
```
kubectl delete k8srequiredlabels ns-must-have-team-label
```
- Verify the constraint is deleted
```
kubectl get k8srequiredlabels
```
# Use Policy Controller metrics
Policy Controller includes multiple metrics related to policy usage. For example, there are metrics recording the number of constraints and constraint templates, and the number audit violations detected. To create and record these metrics, Policy Controller uses OpenCensus. You can configure Policy Controller to export these metrics to Prometheus or Cloud Monitoring. The default setting is to exports the metrics to both Prometheus and Cloud Monitoring.

For more information see Use Policy Controller metrics

# Troubleshooting Policy Controller
For more information see Troubleshoot Policy Controller
