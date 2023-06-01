# Logging and Monitoring on GKE Challenge Lab

## Overview

This lab lets you learn to customize Fluent Bit on a Google Kubernetes Engine cluster to transform unstructured logs to structured logs. You also learn how to host your own configurable Fluent Bit daemonset to send logs to Cloud Logging, instead of selecting the Cloud Logging option when creating the Google Kubernetes Engine (GKE) cluster, which does not allow configuration of the Fluent Bit daemon.

## What you will learn

In this lab, you will learn how to do the following:

- Deploy your own Fluent Bit daemonset on a Google Kubernetes Engine cluster, configured to log data to Cloud Logging
- Transform unstructured GKE log messages to structured ones

## Deploy application

1. Deploy a sample test-logger application that emits logs in multiple formats to the dev-cluster

   - git clone https://github.com/xiangshen-dk/kubernetes-customize-fluentbit.git
   - cd kubernetes-customize-fluentbit
   - docker build -t test-logger test-logger
   - docker tag test-logger gcr.io/${project_id}/test-logger
   - docker push gcr.io/${project_id}/test-logger
   - gcloud container clusters get-credentials dev-cluster --zone=europe-west2-a
   - kubectl apply -f kubernetes/test-logger-deploy.yaml

2. Verify the status of the test-logger pods on the **dev-cluster**
3. Verify the logs i.e. `kubectl logs -l component=test-logger`

## Deploying the Fluent Bit daemonset to your cluster

Because we turned on system-only logging, a GKE-managed Fluentd daemonset is deployed that is responsible for system logging. The Kubernetes manifests for Fluent Bit that you deploy in this procedure are versions of the ones available from the Fluent Bit site for logging using Cloud Logging

1. Deploy the Fluent Bit DaemonSet
   - kubectl apply -f ./kubernetes/fluentbit-rbac.yaml
   - kubectl apply -f kubernetes/fluentbit-configmap.yaml
   - kubectl apply -f kubernetes/fluentbit-daemonset.yaml
   - kubectl get pods --namespace=logging
2. Verify that you're seeing logs in Cloud Logging (hint: select Kubernetes Container as a resource type in the Resource list)
   _you can see the log message from your container is stored as a string in the **log** field under **jsonPayload** regardless of its original format. Additional info such as timestamp is also added to the log field._

## Approaches to transform the logs

### Use the JSON filter

As you see earlier, the **log** field is a long string. You have multiple options to transform it to a json structure. Those options all involve using Fluent Bit filters and you also need some understanding of the format for your raw log messages.

If your log messages are already in JSON format like the example in the previous screenshot, you can use the JSON filter to parse them and view them in jsonPayload. However, before you do that you need to have another pair of parser and filter to remove the extraneous data. You can view an exmaple in [fluentbit-configmap-json.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-json.yaml#L98)

1. Deploy the new version of the ConfigMap to your cluster

   ```
   - kubectl apply -f kubernetes/fluentbit-configmap-updated.yaml
   - kubectl rollout restart  ds/fluent-bit --namespace=logging
   - kubectl rollout status ds/fluent-bit --namespace=logging
   ```

2. After the daemon set has successfully rolled out, you can run the following query in Cloud Logging to view one of the log messages which has a JSON format.

   ```
   resource.type="k8s_container"
   resource.labels.container_name="test-logger"
   "error happened with logging system"
   ```

### Use the Lua and JSON filter

Sometimes, your log strings have an embedded JSON structure or they are not well-formed in JSON. In that case, you can use the Lua filter, which allows you to modify the incoming records using custom Lua scripts.

For example, the following code will extract a string enclosed between **{** and **}** and use it to replace the original **log** field.

```
function extract_json(tag, timestamp, record)
    record["log"] = string.gsub(record["log"], ".-%s*({.*}).*", "%1")
    return 2, timestamp, record
end
```

You can view the example in [fluentbit-configmap-json.yaml](https://github.com/xiangshen-dk/kubernetes-customize-fluentbit/blob/main/kubernetes/fluentbit-configmap-updated.yaml#L45)

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
