#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Exit if any command in a pipeline fails

ID="test"  # Change this to a unique identifier if needed

FOO_NAMESPACE="foo-${ID}"
BAR_NAMESPACE="bar-${ID}"

echo "Creating namespaces..."
kubectl create namespace "$FOO_NAMESPACE" || true
kubectl create namespace "$BAR_NAMESPACE" || true

echo "Deploying kubectl-proxy pod in $FOO_NAMESPACE..."
kubectl apply -f https://raw.githubusercontent.com/k8s-school/k8s-advanced/master/labs/2_authorization/kubectl-proxy.yaml -n "$FOO_NAMESPACE"

echo "Creating services in $FOO_NAMESPACE and $BAR_NAMESPACE..."
kubectl create service clusterip foo-service --tcp=80:80 -n "$FOO_NAMESPACE" || true
kubectl create service clusterip bar-service --tcp=80:80 -n "$BAR_NAMESPACE" || true

echo "Waiting for kubectl-proxy pod to be ready..."
kubectl wait --for=condition=ready pod -l app=kubectl-proxy -n "$FOO_NAMESPACE" --timeout=60s

echo "Fetching kubectl-proxy pod name..."
PROXY_POD=$(kubectl get pods -n "$FOO_NAMESPACE" -l app=kubectl-proxy -o jsonpath="{.items[0].metadata.name}")

echo "Creating RBAC (Role and RoleBinding) in $FOO_NAMESPACE..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: service-reader
  namespace: $FOO_NAMESPACE
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-reader-binding
  namespace: $FOO_NAMESPACE
subjects:
- kind: ServiceAccount
  name: default
  namespace: $FOO_NAMESPACE
roleRef:
  kind: Role
  name: service-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Running tests inside kubectl-proxy pod..."

echo "Testing access to services in $FOO_NAMESPACE (should succeed)..."
kubectl exec -n "$FOO_NAMESPACE" "$PROXY_POD" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/v1/namespaces/"$FOO_NAMESPACE"/services

echo "Testing access to services in $BAR_NAMESPACE (should be forbidden)..."
kubectl exec -n "$FOO_NAMESPACE" "$PROXY_POD" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/v1/namespaces/"$BAR_NAMESPACE"/services

echo "Test completed!"
