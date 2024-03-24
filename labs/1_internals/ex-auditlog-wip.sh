#!/bin/bash

set -euxo pipefail

oc login -u developer https://api.crc.testing:6443
oc new-project ml-app
# Pod will crash because of system error
kubectl run nginx --image=nginx



oc login -u kubeadmin https://api.crc.testing:6443
# TODO - Find the audit log for the pod creation
oc adm node-logs crc-ksq4m-master-0    --path=openshift-apiserver/audit.log \
  | jq 'select(.user.username == "developer")' | jq 'select(.verb == "create")'| jq 'select(.objectRef.resource == "pods")'