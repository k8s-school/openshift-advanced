#!/bin/bash

set -euxo pipefail

kubectl create namespace monitoring
kubectl create clusterrolebinding cluster-monitoring --clusterrole=cluster-admin --serviceaccount=monitoring:default


# To find it use "rbac-tool analysis", and then
kubectl get rolebinding,clusterrolebinding --all-namespaces -o jsonpath="{range .items[?(@.subjects[0].name=='$SERVICE_ACCOUNT_NAME')]}[role: {.roleRef.kind},{.roleRef.name}, binding: {.metadata.name}]{end}"
# it will output:
# [role: ClusterRole,cluster-admin, binding: cluster-monitoring]
