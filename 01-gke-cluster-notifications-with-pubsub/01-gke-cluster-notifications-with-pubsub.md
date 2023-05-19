# GKE cluster notifications with Pub/Sub

## Overview

When certain events occur that are relevant to a GKE cluster, such as important scheduled upgrades or available security bulletins, GKE can publish cluster notifications about those events as messages to a Pub/Sub topics. You can receive these notifications on a Pub/Sub subscription, integrate with third-party services, and filter for the notification types you want to receive.

### Set environment variables

Run the following commands to set the required environment variables

```
echo "export PUBSUB_TOPIC_ID=gke-notifications-topic" >> ~/.bashrc
echo "export PUBSUB_SUBSCRIPTION_ID=gke-notifications-sub" >> ~/.bashrc
source ~/.bashrc
```

### Create a Pub/Sub topic

- Create a Pub/Sub topic

```
gcloud pubsub topics create ${PUBSUB_TOPIC_ID} \
--message-retention-duration=30d
```

- To see the topic from the command line, run the following command

```
gcloud pubsub topics describe ${PUBSUB_TOPIC_ID}
```

- To see the topic in the Console, run the following command and click on the URL

```
echo -e "\nPub/Sub Topic URL: https://console.cloud.google.com/cloudpubsub/topic/detail/${PUBSUB_TOPIC_ID}?project=${GOOGLE_CLOUD_PROJECT}\n"
```

### Enable notifications on an existing cluster

- Enable all notifications on existing-cluster

```
gcloud container clusters update existing-cluster \
--notification-config=pubsub=ENABLED,pubsub-topic=projects/${GOOGLE_CLOUD_PROJECT}/topics/${PUBSUB_TOPIC_ID} \
--zone=us-central1-a
```

### Create a Pub/Sub subscription to the topic

- Create a pull subscription to the topic

```gcloud pubsub subscriptions create ${PUBSUB_SUBSCRIPTION_ID} \
--topic=${PUBSUB_TOPIC_ID}
```

- To see the subscription from the command line, run the following command

```
gcloud pubsub subscriptions describe ${PUBSUB_SUBSCRIPTION_ID}
```

- To see the subscription in the Console, run the following command and click on the URL

```
echo -e "\nPub/Sub Subscription URL: https://console.cloud.google.com/cloudpubsub/subscription/detail/${PUBSUB_SUBSCRIPTION_ID}?project=${GOOGLE_CLOUD_PROJECT}\n"
```

### Verify cluster notifications

- Manually trigger a cluster upgrade

```
gcloud container clusters upgrade existing-cluster \
--quiet \
--zone=us-central1-a
```

- Pull the Pub/Sub subscription and check for a message

```
gcloud pubsub subscriptions pull ${PUBSUB_SUBSCRIPTION_ID}
```

- To see the subscription messages in the Console, run the following command and click on the URL

```
echo -e "\nPub/Sub Subscription Messages URL: https://console.cloud.google.com/cloudpubsub/subscription/detail/${PUBSUB_SUBSCRIPTION_ID}?project=${GOOGLE_CLOUD_PROJECT}&tab=messages\n"
```

Once the page loads, click the PULL button to see the subscription messages.

### Filtering cluster notifications

A filter attribute is available for the notification-config flag that allows you to filter cluster notifications to ensure that you receive only the notifications that you want. The filter attribute takes a pipe(|) delimited list of the notification types that you want to receive.

GKE sends the following cluster notification types:

- SecurityBulletinEvent
- UpgradeAvailableEvent
- UpgradeEvent

For example, specifying filter="UpgradeEvent|SecurityBulletinEvent" tells GKE to only send notifications for UpgradeEvent and SecurityBulletinEvent notification types. See the Cluster notifications documentation for more information.

###
