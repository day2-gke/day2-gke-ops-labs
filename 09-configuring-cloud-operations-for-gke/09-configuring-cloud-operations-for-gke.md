# Configuring Cloud Operations for GKE

## Overview

Google Cloud's operations suite is an integrated monitoring, logging, and trace managed services for applications and systems running on Google Cloud and beyond. Google Kubernetes Engine (GKE) includes integration with Cloud Logging and Cloud Monitoring, as well as Google Cloud Managed Service for Prometheus. When you create a GKE cluster running on Google Cloud, Cloud Logging and Cloud Monitoring are enabled by default and provide observability specifically tailored for Kubernetes.

### What you'll learn

In this lab, you will learn how to:

- Enable Cloud Logging for GKE system and workload logs
- Enable Cloud Monitoring for GKE system metrics
- Enable Managed Prometheus for GKE workload metrics

## Cloud Operations

You can control which logs and which metrics, if any, are sent from your GKE cluster to Cloud Logging and Cloud Monitoring. You can also control whether to enable Google Cloud Managed Service for Prometheus, which lets you monitor and alert on your workloads, using Prometheus, without having to manually manage and operate Prometheus at scale.

### Cloud Logging

You have a choice whether or not to send logs from your GKE cluster to Cloud Logging. If you choose to send logs to Cloud Logging, you must send system logs, and you may optionally send logs from workloads as well.

By default, GKE collects logs for both your system and application workloads deployed to the cluster.

- **System logs** – These logs include the audit logs for the cluster including the Admin Activity log, Data Access log, and the Events log. For detailed information about the Audit Logs for GKE, refer to the Audit Logs for GKE documentation. Some system logs run as containers, such as those for the kube-system, and they're described in Controlling the collection of your application logs.

- **Workload logs** – Kubernetes containers collect logs for your workloads, written to STDOUT and STDERR.

### cloud Monitoring

Cloud Monitoring is a Google Kubernetes Engine (GKE) addon that collects metrics emitted by your applications and by GKE infrastructure.

You have a choice whether or not to send metrics from your GKE cluster to Cloud Monitoring. If you choose to send metrics to Cloud Monitoring, system metrics will be sent.

Workload monitoring is deprecated and is removed in GKE 1.24 and later. Workload monitoring is replaced by Google Cloud Managed Service for Prometheus, which is Google's recommended way to monitor Kubernetes applications by using Cloud Monitoring.

## Enable Cloud Logging integration

- Enable the Cloud Logging integration for only system logs on prod-cluster

```
gcloud container clusters update prod-cluster \
--logging=SYSTEM \
--zone=us-central1-a
```

- Enable the Cloud Logging integration for system and workload logs on prod-cluster

```
gcloud container clusters update prod-cluster \
--logging=SYSTEM,WORKLOAD \
--zone=us-central1-a
```

- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > prod-cluster or run the following command and click on the URL

```
echo -e "\nprod-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/prod-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```

- In the Features section there is a Cloud Logging entry that shows the configured settings. Click the View Logs link to go to the Cloud Logging Log Explorer.

## Enable Cloud Monitoring integration

- Enable the Cloud Monitoring integration for system metrics on prod-cluster

```
gcloud container clusters update prod-cluster \
--monitoring=SYSTEM \
--zone=us-central1-a
```

- Enable Managed Prometheus for workload metrics on prod-cluster

```
gcloud beta container clusters update prod-cluster \
--enable-managed-prometheus \
--zone=us-central1-a
```

- To see the cluster settings in the Console navigate to Kubernetes Engine > Clusters > prod-cluster or run the following command and click on the URL

```
echo -e "\nprod-cluster URL: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/prod-cluster/details?project=${GOOGLE_CLOUD_PROJECT}\n"
```

- In the Features section there is a Cloud Monitoring entry that shows the configured settings. Click the View GKE Dashboard link to go to the Cloud Monitoring GKE Dashboard.
