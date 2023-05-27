# Overview
This lab lets you learn to customize Fluent Bit on a Google Kubernetes Engine cluster to transform unstructured logs to structured logs. You also learn how to host your own configurable Fluent Bit daemonset to send logs to Cloud Logging, instead of selecting the Cloud Logging option when creating the Google Kubernetes Engine (GKE) cluster, which does not allow configuration of the Fluent Bit daemon.

## What you will learn
In this lab, you will learn how to do the following:

- Deploy your own Fluent Bit daemonset on a Google Kubernetes Engine cluster, configured to log data to Cloud Logging

- Transform unstructured GKE log messages to structured ones

Infrastructure setup
Duration: 10:00

Create the GKE cluster
In Cloud Shell, set the environment variables:

export region=us-east1
export zone=${region}-b
export project_id=$(gcloud config get-value project)
Copied!
In Cloud Shell, Set the default zone and project ID so that you don't have to specify these values in every subsequent command:

gcloud config set compute/zone ${zone}
gcloud config set project ${project_id}
Copied!
Create the GKE cluster with system-only logging turned on:
gcloud container clusters create custom-fluentbit \
--zone $zone \
--logging=SYSTEM \
--tags=gke-cluster-with-customized-fluentbit \
--scopes=logging-write,storage-rw
Copied!
Verify the GKE cluster
Connect to a Google Kubernetes Engine cluster and validate that it's been created correctly.

Use the following command to see the cluster's status:

gcloud container clusters list
Copied!
The cluster status will say PROVISIONING. Wait a moment and run the command above again. Repeat until the status is RUNNING. This could take several minutes. Verify that the cluster named central has been created.

You can also check the progress in the Cloud Console - Navigation menu > Kubernetes Engine > Clusters.

Once your cluster has RUNNING status, get the cluster credentials:

gcloud container clusters get-credentials custom-fluentbit --zone $zone
Copied!
(Output)

Fetching cluster endpoint and auth data.
kubeconfig entry generated for central.
Copied!
Verify that the nodes have been created:

kubectl get nodes
Copied!
Your output should look like this:

NAME                                       STATUS    ROLES     AGE       VERSION
gke-custom-fluentbit-default-pool-4d4150d0-7wqr   Ready    <none>   11m   v1.22.8-gke.200
gke-custom-fluentbit-default-pool-4d4150d0-92wq   Ready    <none>   11m   v1.22.8-gke.200
gke-custom-fluentbit-default-pool-4d4150d0-bptp   Ready    <none>   11m   v1.22.8-gke.200
Copied!
Deploy application
Next, you will deploy a sample test-logger application that emits logs in multiple formats.

Run the following to clone the repo:

git clone https://github.com/xiangshen-dk/kubernetes-customize-fluentbit.git
Copied!
Change to the kubernetes-customize-fluentbit directory:

cd kubernetes-customize-fluentbit
Copied!
By default, the sample application that you deploy continuously emits random logging statements. The Docker container is built from the source code under the test-logger subdirectory.

Build the test-logger container image:

docker build -t test-logger test-logger
Copied!
Tag the container before pushing it to the registry:

docker tag test-logger gcr.io/${project_id}/test-logger
Copied!
Push the container image:

docker push gcr.io/${project_id}/test-logger
Copied!
Update the deployment file:

envsubst < kubernetes/test-logger.yaml > kubernetes/test-logger-deploy.yaml
Copied!
Deploy the test-logger application to the GKE cluster:

kubectl apply -f kubernetes/test-logger-deploy.yaml
Copied!
View the status of the test-logger pods:

kubectl get pods
Copied!
Repeat this command until the output looks like the following, with all three test-logger pods running:

NAME                           READY   STATUS    RESTARTS   AGE
test-logger-58f7bfdb89-4d2b5   1/1     Running   0          28s
test-logger-58f7bfdb89-qrlbl   1/1     Running   0          28s
test-logger-58f7bfdb89-xfrkx   1/1     Running   0          28s
Copied!
The test-logger pods will continuously print messages randomly selected from the following for demo purposes. You can find the source in the logger.go file.

 {"Error": true, "Code": 1234, "Message": "error happened with logging system"}
 Another test {"Info": "Processing system events", "Code": 101} end
 data:100 0.5 true This is an example
 Note: nothing happened
Copied!
To verify, you can pick one of the pods and use the command kubectl logs to view the logs. For example:

kubectl logs -l component=test-logger
Copied!
Deploying the Fluent Bit daemonset to your cluster
Duration: 10:00

In this section, you configure and deploy your Fluent Bit daemonset.

Because you turned on system-only logging, a GKE-managed Fluentd daemonset is deployed that is responsible for system logging. The Kubernetes manifests for Fluent Bit that you deploy in this procedure are versions of the ones available from the Fluent Bit site for logging using Cloud Logging and watching changes to Docker log files.

Create the service account and the cluster role in a new logging namespace:

kubectl apply -f ./kubernetes/fluentbit-rbac.yaml
Copied!
Deploy the Fluent Bit configuration:

kubectl apply -f kubernetes/fluentbit-configmap.yaml
Copied!
Deploy the Fluent Bit daemonset:

kubectl apply -f kubernetes/fluentbit-daemonset.yaml
Copied!
Check that the Fluent Bit pods have started:

kubectl get pods --namespace=logging
Copied!
If they're running, you see output like the following:

NAME               READY   STATUS    RESTARTS   AGE
fluent-bit-246wz   1/1     Running   0          26s
fluent-bit-6h6ww   1/1     Running   0          26s
fluent-bit-zpp8q   1/1     Running   0          26s
Copied!
For details on configuring Fluent Bit for Kubernetes, see the Fluent Bit manual.

Verify that you're seeing logs in Cloud Logging. In the console, on the left-hand side, select Logging > Logs Explorer, and then select Kubernetes Container as a resource type in the Resource list.

In the Logs fields, select test-logger for CONTAINER_NAME and you should see logs from our test containers. Expand one of the log entries, and you can see the log message from your container is stored as a string in the **log** field under **jsonPayload** regardless of its original format. Additional info such as timestamp is also added to the log field.

Click Run Query.

Alternatively, you can run the following query in the query window:

resource.type="k8s_container"
resource.labels.container_name="test-logger"
Copied!
In the query results window, select a row and expand the jsonPayload field. You should see something like the following. Your log message might be different but everything would be in the **log** field.

483161ae9e243f84.png
Approaches to transform the logs
Duration: 10:00

As you see earlier, the **log** field is a long string. You have multiple options to transform it to a json structure. Those options all involve using Fluent Bit filters and you also need some understanding of the format for your raw log messages.

## Use the JSON filter
If your log messages are already in JSON format like the example in the previous screenshot, you can use the JSON filter to parse them and view them in jsonPayload. However, before you do that you need to have another pair of parser and filter to remove the extraneous data. For example, use the following parser to extract your log string:
```
[PARSER]
        Name        containerd
        Format      regex
        Regex       ^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
```
And use the following filters to transform the log messages:
```
[FILTER]
        Name         parser
        Match        kube.*
        Key_Name     log
        Reserve_Data True
        Parser       containerd
    
    [FILTER]
        Name         parser
        Match        kube.*
        Key_Name     log
        Parser       json
```
> Note: You can view a complete example in [fluentbit-configmap-json.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-json.yaml#L98).

Deploy the new version of the ConfigMap to your cluster:
```
kubectl apply -f kubernetes/fluentbit-configmap-updated.yaml
```
Roll out the new version of the daemonset:
```
kubectl rollout restart  ds/fluent-bit --namespace=logging
```
Roll out the update and wait for it to complete:
```
kubectl rollout status ds/fluent-bit --namespace=logging
```
When it completes, you should see the following message:
```
daemon set "fluent-bit" successfully rolled out
```
After the daemon set has successfully rolled out, you can run the following query to view one of the log messages which has a JSON format.
```
resource.type="k8s_container"
resource.labels.container_name="test-logger"
"error happened with logging system"
```
In the query result window, you can now see the jsonPayload is different - the log field is gone and you have a structured JSON from the string.

f076d0802883200c.png
## Use the Lua and JSON filter
Sometimes, your log strings have an embedded JSON structure or they are not well-formed in JSON. In that case, you can use the Lua filter, which allows you to modify the incoming records using custom Lua scripts.

For example, the following code will extract a string enclosed between **{** and **}** and use it to replace the original **log** field.
```
function extract_json(tag, timestamp, record)
    record["log"] = string.gsub(record["log"], ".-%s*({.*}).*", "%1")
    return 2, timestamp, record
end
```
> Note: You can view the example in [fluentbit-configmap-updated.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-updated.yaml#L45)

If the code is executed on the log field for the following string
```
Another test {"Info": "Processing system events", "Code": 101} end
```
the new log field will be the following:
```
 {"Info": "Processing system events", "Code": 101}
```
Since the new string has a well-formed JSON format, you can use the JSON filter. For example:
```
[FILTER]
        Name                parser
        Match               kube.*
        Key_Name            log
        Parser              json
```
With this transformation, you will see the logs for this message has the following structure in Cloud Logging:
```
jsonPayload: {
      Code: 101
      Info: "Processing system events"
    }
```
## Use a custom filter with Regex
If your logs have a static format, you can create a custom parser filter with regex. For example:
```
 [PARSER]
        Name my_paser
        Format regex
        Regex ^(?<time>.+) (?<output>.+ .+) data:(?<int>[^ ]+) (?<float>[^ ]+) (?<bool>[^ ]+) (?<string>.+)$
```
> Note: You can view the example in [fluentbit-configmap-updated.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-updated.yaml#L93).

And you can use this parser in a filter:
```
 [FILTER]
        Name                parser
        Match               kube.*
        Key_Name            log
        Parser              my_paser
```
With this configuration, the following string:
```
 data:100 0.5 true This is example
```
will be transformed to:
```
jsonPayload: {
      bool: "true"
      float: "0.5"
      int: "100"
      output: "stdout F"
      string: "This is example"
      time: "2022-04-19T13:53:21.701054631Z"
    }
Info: "Processing system events"
    }
```
# Combining filters
Duration: 10:00

You can combine multiple filters for different log messages. In this section, you will use a new configuration with combined filters for Fluent Bit to transform the sample log messages. Read the [fluentbit-configmap-updated.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-updated.yaml) for details.

Deploy the new version of the ConfigMap to your cluster:
```
kubectl apply -f kubernetes/fluentbit-configmap-updated.yaml
```
Roll out the new version of the daemonset:
```
kubectl rollout restart  ds/fluent-bit --namespace=logging
```
Roll out the update and wait for it to complete:
```
kubectl rollout status ds/fluent-bit --namespace=logging
```
When it completes, you should see the following message:
```
daemon set "fluent-bit" successfully rolled out
```
When the rollout is complete, refresh the Cloud Logging logs. You may need to update the query:
```
resource.type="k8s_container"
resource.labels.container_name="test-logger"
```
Click Run Query.

If you expand the log entries, you should see the updated jsonPayloads. For example:

fbbb331b7594d58d.png
As mentioned earlier, the relevant log messages are transformed to JSON. If log messages don't match in any filter, they will be left unchanged. For example, you can see the message 
> **Note: nothing happened** is still kept in the log field without any changes.

