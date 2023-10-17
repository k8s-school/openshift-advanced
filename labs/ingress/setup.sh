#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NSAPP="ingress-app"


# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete project -l "ingress=nginx"
oc new-project "$NSAPP"
kubectl label ns "$NSAPP" "ingress=nginx"

# Deploy application
kubectl create deployment web -n "$NSAPP" --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web -n "$NSAPP" --port=8080
kubectl  wait -n "$NSAPP" --for=condition=available deployment web

# Create ingress route
kubectl apply -n "$NSAPP" -f $DIR/example-ingress.yaml
kubectl get -n "$NSAPP" ingress

echo "INFO: Add application URL to DNS"
export server_ip=$(ip add show eth0 | grep -w inet | awk '{print $2;exit}' | cut -d'/' -f1)
go install github.com/txn2/txeh/txeh@v1.5.4
sudo $(which txeh) add "$server_ip" hello-world.info

echo "INFO: access the application via ingress"
curl -k https://hello-world.info
