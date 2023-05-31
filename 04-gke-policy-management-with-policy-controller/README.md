# Logging and Monitoring on GKE Challenge Lab

## Overview

Policy Controller enables the enforcement of fully programmable policies for your clusters. These policies act as "guardrails" and prevent any changes to the configuration of the Kubernetes API from violating security, operational, or compliance controls.

Policy Controller enforces policies by using constraints and constraint templates. It is based on the open source Open Policy Agent Gatekeeper project and comes with a full library of pre-built policies for common security and compliance controls.

## What you will learn

In this lab, you will learn how to do the following:

- Try out Policy Controller
- Install Policy Controller
- Review the constraint templates in the default template library
- Define a constraint
- Fix violations
- Remove a constraint
- Use Policy Controller metrics
- Troubleshoot Policy Controller

## Constraint Templates

1. Connect to **prod-cluster** and list all Google provided constraints using `kubectl`
2. Describe the `k8srequiredlabels` constraint template

## Define a constraint

1. Apply the following constraint to the **prod-cluster**
   ```
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
   ```
2. Verify the constraint has been applied
3. Describe the ns-must-have-team-label constraint to verify violations

## Fix Violations

1. Apply a team label to the following namespaces

   ```
   config-management-monitoring
   config-management-system
   default
   gatekeeper-system
   kube-node-lease
   kube-public
   kube-system
   ```

2. Describe the ns-must-have-team-label constraint to verify violations
3. Test the constraint by creating a new Namespace without a label called `app-team-a`
4. Apply the following Namespace with a label and verify it's been successfully created
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
