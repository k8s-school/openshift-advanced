#!/bin/bash

set -euxo pipefail

node="crc-ksq4m-master-0"

oc login -u developer https://api.crc.testing:6443
oc new-project ml-app
# Pod will crash because of system error
kubectl run nginx --image=nginx



oc login -u kubeadmin https://api.crc.testing:6443
# TODO - Find the audit log for the pod creation
oc adm node-logs "$node" --path=openshift-apiserver/audit.log \
  | jq 'select(.user.username == "developer" and .verb == "create" and .objectRef.resource == "pods")'

oc adm node-logs "$node" \
  --path=oauth-apiserver/audit.log \
  | jq 'select(.verb != "get")'