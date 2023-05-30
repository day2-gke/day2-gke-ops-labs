# GKE Monitoring Dashboards

## Overview

This lab teaches you how to use and manage GKE dashboards to monitor resource utilization and visualize critical metrics.

### What you will learn

In this lab, you will learn how to do the following:

- Navigate the out-of-the-box GKE dashboards to view operational data
- Import and update custom dashboards
- Create and share custom dashboards

### The demo application used in the lab

To use a concrete example, you will work through a scenario based on a sample [microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) app deployed to a GKE cluster. In this demo app, there are many microservices and dependencies among them.

## Infrastructure setup

### Verify the GKE cluster

Connect to a Google Kubernetes Engine cluster and validate that it's been created correctly.

In Cloud Shell, set the zone in gcloud:

```
gcloud config set compute/zone us-central1-a
```

Set the Project ID variable:

```
export PROJECT_ID=$(gcloud info --format='value(config.project)')
```

Use the following command to see the cluster's status:

```
gcloud container clusters list
```

The cluster status will say PROVISIONING. Wait a moment and run the command above again. Repeat until the status is RUNNING. This could take several minutes. Verify that the cluster named day2-ops has been created.

You can also check the progress in the Cloud Console - Navigation menu > Kubernetes Engine > Clusters.

Once your cluster has RUNNING status, get the cluster credentials:

```
gcloud container clusters get-credentials day2-ops --zone us-central1-a
```

Verify that the nodes have been created:

```
kubectl get nodes
```

Your output should look like this:

```
NAME                                            STATUS   ROLES    AGE     VERSION
gke-day2-ops-day2-ops-node-pool-ed40e69b-9j1g   Ready    <none>   6m34s   v1.21.10-gke.2000
gke-day2-ops-day2-ops-node-pool-ed40e69b-v12n   Ready    <none>   6m35s   v1.21.10-gke.2000
gke-day2-ops-day2-ops-node-pool-ed40e69b-v9j1   Ready    <none>   6m35s   v1.21.10-gke.2000
```

## Deploy application

Next, you will deploy a microservices application called Hipster Shop to your cluster to create an actual workload you can monitor.

Run the following to clone the repo:

```
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
```

Change to the microservices-demo directory:

```
cd microservices-demo
```

Install the app using kubectl:

```
kubectl apply -f release/kubernetes-manifests.yaml
```

Confirm everything is running correctly:

```
kubectl get pods
```

The output should look similar to the output below. Rerun the command until all pods are reporting a Running status before moving to the next step.

```
NAME                                     READY     STATUS    RESTARTS   AGE
adservice-55f94cfd9c-4lvml               1/1       Running   0          20m
cartservice-6f4946f9b8-6wtff             1/1       Running   2          20m
checkoutservice-5688779d8c-l6crl         1/1       Running   0          20m
currencyservice-665d6f4569-b4sbm         1/1       Running   0          20m
emailservice-684c89bcb8-h48sq            1/1       Running   0          20m
frontend-67c8475b7d-vktsn                1/1       Running   0          20m
loadgenerator-6d646566db-p422w           1/1       Running   0          20m
paymentservice-858d89d64c-hmpkg          1/1       Running   0          20m
productcatalogservice-bcd85cb5-d6xp4     1/1       Running   0          20m
recommendationservice-685d7d6cd9-pxd9g   1/1       Running   0          20m
redis-cart-9b864d47f-c9xc6               1/1       Running   0          20m
shippingservice-5948f9fb5c-vndcp         1/1       Running   0          20m
```

Run the following to get the external IP of the application. This command will only return an IP address once the service has been deployed. So, you may need to repeat the command until there's an external IP address assigned:

```
export EXTERNAL_IP=$(kubectl get service frontend-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

Finally, confirm that the app is up and running:

```
curl -o /dev/null -s -w "%{http_code}\n"  http://${EXTERNAL_IP}
```

Your confirmation will look like this:

```
200
```

After the application is deployed, you can also go to the Cloud Console and view the status.

In the Kubernetes Engine > Workloads page you'll see that all the pods are OK.

Click any workload name, such as adservice, you are able to view its resource usage. Now click on Services & Ingress, verify all services are OK. Stay on this screen to set up monitoring for the application.

### Open the application

Under Service & Ingress, click the Endpoint IP of the service frontend-external.

## Use the existing dashboards

### View the default GKE dashboard

You can click the **ADD FILTER** button to add filters. Alternatively, you can hover over a resource, when the filter icon is displayed, click it to add the resource to the filter field.

### Import a sample GKE monitoring dashboard

You can also import dashboards from the sample library. For example, under the sample library tab, you can click IMPORT to import the GKE Cluster Monitoring dashboard under the Compute category.

type in Mean for the Legend template of Time series A and Max for the Legend template of Time Series B. Since Autosave is on, you can exit the edit mode and you will see the legends of the chart have been changed.

## Create a new dashboard

You can create any new dashboard from the Dashboards page under Cloud Monitoring. Alternatively, you can save a custom chart and create a new dashboard simultaneously from the Metrics explorer. In this lab, you can go to Monitoring -> Dashboards and click CREATE DASHBOARD.

The dashboard editor page will open and you can add a variety of charts and text boxes to your dashboard.

From the chart library or the ADD CHART dropdown menu, add a line chart. By default, a chart for VM instances will be added to the dashboard. You can change the resource and metric you want to use. For example, you can type in kubernetes and select Container -> CPU limit utilization to update the chart.

Next, you can add a table with the metric: Kubernetes Container > container > Memory request

Click CREATE DASHBOARD FILTERS, and you can add two types of filters: dashboard filters let you apply the filter to all charts in the dashboard; template variables let you apply filters to one or more specific charts.

Click ADD to add a zone filter as a Dashboard filter. Add PODNAME as a template variable and only apply to the CPU limit utilization chart. You should have a page like the following.

Change the dashboard name to My GKE Dashboard. Notice the Autosave is on by default. So all your changes will be saved automatically.

Click CLOSE EDITOR and you should have the new dashboard with two charts. Notice the filters you have created.

## Share a dashboard

To share a dashboard, you can get the JSON file for the dashboard and share the file. For example, when you are on the dashboard editor page, click JSON EDITOR.

From the button JSON Editor, you can download the JSON file and save it. Close the dashboard editor and go back to the initial dashboard page. Click CREATE DASHBOARD and create a new one again.

Click JSON EDITOR, and you can upload the file you just saved.

Now you should have your original dashboard back. Change the name of the dashboard and close the editor. You will see a new dashboard has been created.

Alternatively, you can also use the dashboard API or gcloud to export and import the JSON files.
