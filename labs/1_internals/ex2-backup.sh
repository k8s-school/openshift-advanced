#!/bin/bash

set -euxo pipefail

ns="openshift-etcd"
labels="app=etcd,etcd=true,k8s-app=etcd"

kubectl get pods -n $ns
kubectl  wait --for=condition=Ready -n $ns pods -l "$labels"
etcd_pod=$(kubectl get pods -n $ns -l "$labels" -o jsonpath='{.items[0].metadata.name}')

kubectl exec -t -n $ns "$etcd_pod" --  \
    sh -c "ETCDCTL_API=3 etcdctl \
    snapshot save /var/lib/etcd/etcd-snapshot.db"

kubectl exec -t -n $ns "$etcd_pod" --  \
    sh -c "ETCDCTL_API=3 etcdctl \
    -w fields snapshot status /var/lib/etcd/etcd-snapshot.db"
