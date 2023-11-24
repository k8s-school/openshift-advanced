# openshift-install

## What does the installer 'destroy' cmd?

Undocumented, and debug log are not useful
"openshift-install destroy -h" does not help

Having a look at the code it seems it stop and then remove the VMs.
See https://github.com/openshift/installer/blob/master/cmd/openshift-install/destroy.go
and https://github.com/openshift/installer/blob/dd15963db02cabddf2c26870d230bd1fbbaddb0c/pkg/destroy/ovirt/destroyer.go#L63C2-L63C24

# Machine api

## How to troubleshoot machine-api?

Explanation for the "orphan machine" use case (creation of of machine using the export of an existing machine in a machineset) is available [here](./infra/az/machineset/failure-examples).

## Machine-api operator documentation:

https://github.com/openshift/machine-api-operator/tree/master#readme

# RBAC

## How to list all verbs?

See https://stackoverflow.com/questions/57661494/list-of-kubernetes-rbac-rule-verbs

```shell
kubectl proxy --port=8080
curl -s http://localhost:8080/api/v1 | jq '.resources[] | [.name, (.verbs | join(" "))] | join(" = ")' -r
```

# Disaster recovery

# Key Recovery Objectives
Among the components of a DR plan are two key parameters that define how long your business can afford to be offline and how much data loss it can tolerate. These are the **Recovery Time Objective** (RTO) and **Recovery Point Objective** (RPO).

**RTO** is the goal your organization sets for the maximum length of time it should take to restore normal operations following an outage or data loss.

**RPO** is your goal for the maximum amount of data the organization can tolerate losing. This parameter is measured in time: from the moment a failure occurs to your last valid data backup. For example, if you experience a failure now and your last full data backup was 24 hours ago, the RPO is 24 hours.

## etcd troubleshooting

[backing up etcd data](https://docs.openshift.com/container-platform/4.14/backup_and_restore/control_plane_backup_and_restore/backing-up-etcd.html#backing-up-etcd-data_backup-etcd)

[replacing unhealthy etcd member](https://docs.openshift.com/container-platform/4.14/backup_and_restore/control_plane_backup_and_restore/replacing-unhealthy-etcd-member.html#restore-replace-crashlooping-etcd-member_replacing-unhealthy-etcd-member)

[disaster recovery : restoring cluster state](https://docs.openshift.com/container-platform/4.14/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/scenario-2-restoring-cluster-state.html)

[hosted control plane : backup-restore](https://docs.openshift.com/container-platform/4.14/hosted_control_planes/hcp-backup-restore-dr.html#hcp-backup-restore)




