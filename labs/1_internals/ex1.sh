#!/bin/bash

set -euxo pipefail

ns="openshift-etcd"
labels="app=etcd,etcd=true,k8s-app=etcd"

kubectl get pods -n "$ns"
kubectl  wait --timeout=240s --for=condition=Ready -n "$ns" pods -l "app=etcd,etcd=true,k8s-app=etcd"
kubectl get pods -n "$ns"
etcd_pod=$(kubectl get pods -n "$ns" -l "app=etcd,etcd=true,k8s-app=etcd" -o jsonpath='{.items[0].metadata.name}')

# Display Kubernetes keys
kubectl exec -t -n "$ns" "$etcd_pod" -- etcdctl get /kubernetes.io --keys-only --prefix

# Display OpenShift keys (CustomResources)
kubectl exec -t -n "$ns" "$etcd_pod" --  \
    sh -c "echo \$ETCDCTL_CERT \$ETCDCTL_KEY \$ETCDCTL_CACERT && etcdctl get /openshift.io --keys-only --prefix"