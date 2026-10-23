#!/bin/bash

set -euxo pipefail

# Per-trainee namespace: the cluster may be shared
ID="${ID:-$(whoami)}"
kubectl delete ns -l "quota=$ID"
NS="quota-object-example-$ID"
kubectl create namespace "$NS"
kubectl label ns "$NS" "quota=$ID"
 
kubectl apply -f https://k8s.io/examples/admin/resource/quota-objects.yaml --namespace="$NS"
kubectl get resourcequota object-quota-demo --namespace="$NS" --output=yaml
kubectl apply -f https://k8s.io/examples/admin/resource/quota-objects-pvc.yaml --namespace="$NS"
kubectl get persistentvolumeclaims --namespace="$NS"
kubectl apply -f https://k8s.io/examples/admin/resource/quota-objects-pvc-2.yaml --namespace="$NS" || 
    ink -y "EXPECTED ERROR: failed to exceed quota"
kubectl get persistentvolumeclaims --namespace="$NS"
