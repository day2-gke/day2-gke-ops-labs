# Overview
[Backup for GKE](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke) is a service for backing up and restoring workloads in GKE clusters. It has two components:

A Google Cloud API serves as the control plane for the service.
A GKE add-on (the Backup for GKE agent) must be enabled in each cluster for which you wish to perform backup and restore operations.
Backups of your workloads may be useful for disaster recovery, CI/CD pipelines, cloning workloads, or upgrade scenarios. Protecting your workloads can help you achieve business-critical recovery point objectives.

## What you'll learn
In this lab, you will learn how to:

- Enable Backup for a GKE cluster
- Deploy a stateful application with a database on GKE
- Plan and backup GKE workloads
- Restore a backup

## Set up the environment
A GKE cluster and a static external IP address were provisioned as part of the lab setup.

- Run the following commands to set the required environment variables:
```
echo "export ZONE=us-central1-a" >> ~/.bashrc
echo "export REGION=us-central1" >> ~/.bashrc
echo "export PROJECT_ID=`gcloud config get-value core/project`" >> ~/.bashrc
echo "export BACKUP_PLAN=my-backup-plan" >> ~/.bashrc
source ~/.bashrc
echo "export EXTERNAL_ADDRESS=$(gcloud compute addresses describe app-address --format='value(address)' --region $REGION)" >> ~/.bashrc
source ~/.bashrc
```
# Task 1. Enable Backup for GKE
1. Enable the Backup for GKE APIs:
```
gcloud services enable gkebackup.googleapis.com
```
Copied!
You should see the following success message:
```
Operation "operations/####.##-############-########-####-####-####-############" finished successfully.
```
2. Enable Backup for GKE on an existing cluster. You can enable Backup when you create a new cluster, but for this lab you will enable it on an existing cluster:
```
gcloud beta container clusters update lab-cluster \
--project=$PROJECT_ID  \
--update-addons=BackupRestore=ENABLED \
--zone=$ZONE
```
Your results should look like this:
```
Updating lab-cluster...done.
Updated [https://container.googleapis.com/v1beta1/projects/qwiklabs-gcp-##-############/zones/us-central1-a/clusters/lab-cluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1-a/lab-cluster?project=qwiklabs-gcp-##-############
```
3. Verify Backup for GKE is enabled on the cluster
```
gcloud beta container clusters describe lab-cluster \
--project=$PROJECT_ID  \
--zone=$ZONE | grep -A 1 gkeBackupAgentConfig:
```

# Task 2. Create a backup plan

1. Run the following to create a backup plan:
```
gcloud beta container backup-restore backup-plans create $BACKUP_PLAN \
--project=$PROJECT_ID \
--location=$REGION \
--cluster=projects/${PROJECT_ID}/locations/${ZONE}/clusters/lab-cluster \
--all-namespaces \
--include-secrets \
--include-volume-data \
--cron-schedule="10 3 * * *" \
--backup-retain-days=30
```
You will see the following when it is complete.
```
Create request issued for: [my-backup-plan]
Waiting for operation [projects/qwiklabs-gcp-##-############/locations/us-central1/operations/operation-#############-#############-########-########] to complete...working...
Waiting for operation [projects/qwiklabs-gcp-##-############/locations/us-central1/operations/operation-#############-#############-########-########] to complete...done.
ㅤ
Created backup plan [my-backup-plan].
```
2. Verify the backup plans was created:
```
gcloud beta container backup-restore backup-plans list \
--project=$PROJECT_ID \
--location=$REGION
```
You will see the following verification:
```
NAME: my-backup-plan
LOCATION: us-central1
CLUSTER: lab-cluster
ACTIVE: Y
PAUSED: N
```
3. View the details of a backup plan:
```
gcloud beta container backup-restore backup-plans describe $BACKUP_PLAN \
--project=$PROJECT_ID \
--location=$REGION
```
You details should look like this:
```
backupConfig:
  allNamespaces: true
  includeSecrets: true
  includeVolumeData: true
backupSchedule:
  cronSchedule: 10 3 * * *
cluster: projects/qwiklabs-gcp-##-############/locations/us-central1-a/clusters/lab-cluster
createTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
etag: '#'
name: projects/qwiklabs-gcp-##-############/locations/us-central1/backupPlans/my-backup-plan
retentionPolicy:
  backupRetainDays: 30
uid: ########-####-####-####-############
updateTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
```
# Task 3. Deploy WordPress with MySQL to the cluster
1. Get credentials for lab-cluster:
```
gcloud container clusters get-credentials lab-cluster \
--zone=$ZONE
```
You credentials should look like the following:
```
Fetching cluster endpoint and auth data.
kubeconfig entry generated for existing-cluster.
```
2. Ensure the reserved static IP address for the application is set:
```
echo "EXTERNAL_ADDRESS=${EXTERNAL_ADDRESS}"
```
The output should look like this:
```
EXTERNAL_ADDRESS=###.###.###.###
```
# Task 4. Deploy the application
You are now ready to deploy a stateful application. You will deploy the WordPress application using MySQL as the database.

1. Run the following commands create persistent volumes for the application and database. The service will also be exposed through a Google Cloud external load balancer:
```
# Password for lab only. Change to a strong one in your environment.
YOUR_SECRET_PASSWORD=1234567890
kubectl create secret generic mysql-pass --from-literal=password=${YOUR_SECRET_PASSWORD?}
kubectl apply -f https://k8s.io/examples/application/wordpress/mysql-deployment.yaml
kubectl apply -f https://k8s.io/examples/application/wordpress/wordpress-deployment.yaml
```
Your results should look like the following:
```
secret/mysql-pass created
service/wordpress-mysql created
persistentvolumeclaim/mysql-pv-claim created
deployment.apps/wordpress-mysql created
service/wordpress created
persistentvolumeclaim/wp-pv-claim created
deployment.apps/wordpress created
```
2. Patch the service to use EXTERNAL_ADDRESS:
```
patch_file=/tmp/loadbalancer-patch.yaml
cat <<EOF > ${patch_file}
spec:
  loadBalancerIP: ${EXTERNAL_ADDRESS}
EOF
kubectl patch service/wordpress --patch "$(cat ${patch_file})"
```
3. Wait for the application to be accessible:
```
while ! curl --fail --max-time 5 --output /dev/null --show-error --silent http://${EXTERNAL_ADDRESS}; do
  sleep 5
done
echo -e "\nhttp://${EXTERNAL_ADDRESS} is accessible\n"
```
When the application is accessible, you should see the following output:
```
...
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5001 milliseconds
curl: (28) Connection timed out after 5000 milliseconds
curl: (28) Connection timed out after 5000 milliseconds
curl: (28) Connection timed out after 5000 milliseconds
curl: (28) Connection timed out after 5000 milliseconds
ㅤ
http://###.###.###.### is accessible
```

# Task 5. Verify the deployed workload
1. In the Cloud console, navigate to Kubernetes Engine > Workload. You should see the WordPress application and its database.
gke_wordpress

2. Open a browser window and paste in the URL from the previous step. You should see the following page:
wordpress_start

3. Click the Continue button and type in the required info. For example:

4. Make a note of the password and click the Install WordPress button.
  
After you log in to the WordPress application, try to create some new posts and add a few comments to existing posts. After backup/restore, you want to verify your input still exists.


# Task 6. Create a backup
1. Create a backup based on the backup plan:
```
gcloud beta container backup-restore backups create my-backup1 \
--project=$PROJECT_ID \
--location=$REGION \
--backup-plan=$BACKUP_PLAN \
--wait-for-completion
```
Your results should look like this:
```
Create in progress for backup my-backup1 [projects/qwiklabs-gcp-##-############/locations/us-central1/operations/operation-#############-#############-########-########].
Creating backup my-backup1...done.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Backup completed. Backup state: SUCCEEDED
```
2. View the backups:
```
gcloud beta container backup-restore backups list \
--project=$PROJECT_ID \
--location=$REGION \
--backup-plan=$BACKUP_PLAN
```
Your backups should look like this:
```
NAME: my-backup1
LOCATION: us-central1
BACKUP_PLAN: my-backup-plan
CREATE_TIME: YYYY-MM-DDTHH:MM:SS UTC
COMPLETE_TIME: YYYY-MM-DDTHH:MM:SS UTC
STATE: SUCCEEDED
```
3. View the details of the backup:
```
gcloud beta container backup-restore backups describe my-backup1 \
--project=$PROJECT_ID \
--location=$REGION \
--backup-plan=$BACKUP_PLAN
```
Details of the backup should be similar to this:
```
allNamespaces: true
clusterMetadata:
  backupCrdVersions:
    backupjobs.gkebackup.gke.io: v1alpha2
    protectedapplicationgroups.gkebackup.gke.io: v1alpha2
    protectedapplications.gkebackup.gke.io: v1alpha2
    restorejobs.gkebackup.gke.io: v1alpha2
  cluster: projects/qwiklabs-gcp-##-############/locations/us-central1-a/clusters/lab-cluster
  gkeVersion: v##.##.##-gke.###
  k8sVersion: '##.##'
completeTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
configBackupSizeBytes: '######'
containsSecrets: true
containsVolumeData: true
createTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
deleteLockExpireTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
etag: '#'
manual: true
name: projects/qwiklabs-gcp-##-############/locations/us-central1/backupPlans/my-backup-plan/backups/my-backup1
podCount: 2
resourceCount: 1396
retainDays: 30
retainExpireTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
sizeBytes: '########'
state: SUCCEEDED
uid: ########-####-####-####-############
updateTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
volumeCount: 2
```
# Task 7. Delete the application
You can restore the backup on the same cluster or a different one. In this lab, you will perform a restore on the same cluster. B.

1. Delete the running application:
```
kubectl delete secret mysql-pass
kubectl delete -f https://k8s.io/examples/application/wordpress/mysql-deployment.yaml
kubectl delete -f https://k8s.io/examples/application/wordpress/wordpress-deployment.yaml
```
Copied!
When the applications are deleted, you will see the following:
```
secret "mysql-pass" deleted
service "wordpress-mysql" deleted
persistentvolumeclaim "mysql-pv-claim" deleted
deployment.apps "wordpress-mysql" deleted
service "wordpress" deleted
persistentvolumeclaim "wp-pv-claim" deleted
deployment.apps "wordpress" deleted
```
2. Verify the workload is deleted from the [GKE workload page](https://console.cloud.google.com/kubernetes/workload/)
Or from CloudShell by running the following:
```
kubectl get pods
```
You will see that nothing is found:
```
No resources found in default namespace.
```
3. Verify you cannot access the application
```
echo -e "\nWordPress URL: http://${EXTERNAL_ADDRESS}\n"
```
Click on the URL and verify it is not functional.

# Task 8. Plan a restore
1. Create a restore plan:
```
gcloud beta container backup-restore restore-plans create my-restore-plan1 \
--project=$PROJECT_ID \
--location=$REGION \
--backup-plan=projects/${PROJECT_ID}/locations/${REGION}/backupPlans/$BACKUP_PLAN \
--cluster=projects/${PROJECT_ID}/locations/${ZONE}/clusters/lab-cluster \
--namespaced-resource-restore-mode=delete-and-restore \
--volume-data-restore-policy=restore-volume-data-from-backup \
--all-namespaces
```
Your output should look like the following:
```
Create request issued for: [my-restore-plan1]
Waiting for operation [projects/qwiklabs-gcp-##-############/locations/us-central1/operations/
operation-#############-#############-########-########] to complete...working.
Waiting for operation [projects/qwiklabs-gcp-##-############/locations/us-central1/operations/operation-#############-#############-########-########] to complete...done.
Created restore plan [my-restore-plan1].
```
2. View the restore plans:
```
gcloud beta container backup-restore restore-plans list \
--project=$PROJECT_ID \
--location=$REGION
```
3. View the details of a restore plan
```
gcloud beta container backup-restore restore-plans describe my-restore-plan1 \
--project=$PROJECT_ID \
--location=$REGION
```
Your restore plan should look like the following:
```
backupPlan: projects/qwiklabs-gcp-##-############/locations/us-central1/backupPlans/my-backup-plan
cluster: projects/qwiklabs-gcp-##-############/locations/us-central1-a/clusters/lab-cluster
createTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
etag: '1'
name: projects/qwiklabs-gcp-##-############/locations/us-central1/restorePlans/my-restore-plan1
restoreConfig:
  allNamespaces: true
  namespacedResourceRestoreMode: DELETE_AND_RESTORE
  volumeDataRestorePolicy: RESTORE_VOLUME_DATA_FROM_BACKUP
uid: ########-####-####-####-############
updateTime: 'YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ'
```
# Task 9. Restore a backup
1. Restore from the backup
```
gcloud beta container backup-restore restores create my-restore1 \
--project=$PROJECT_ID \
--location=$REGION \
--restore-plan=my-restore-plan1 \
--backup=projects/${PROJECT_ID}/locations/${REGION}/backupPlans/${BACKUP_PLAN}/backups/my-backup1 \
--wait-for-completion
```
Your progress should look like this:

2. Verify the application is running:
```
kubectl get pods
```
3. Wait until the all pods have a STATUS of RUNNING

4. Verify you can access the application
```
echo -e "\nWordPress URL: http://${EXTERNAL_ADDRESS}\n"
```
  5. Click on the URL and verify the application is functional.
