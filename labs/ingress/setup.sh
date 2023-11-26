#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NSAPP="ingress-app"


# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete project -l "kubernetes.io/metadata.name=$NSAPP"
oc new-project "$NSAPP"

ink "Deploy application"
set -x
kubectl create deployment web -n "$NSAPP" --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web -n "$NSAPP" --port=8080
kubectl  wait -n "$NSAPP" --for=condition=available deployment web

set +x
ink "Create ingress route"
set -x
kubectl apply -n "$NSAPP" -f $DIR/example-ingress.yaml
kubectl get -n "$NSAPP" ingress

set +x
ink "INFO: Add application URL to DNS (/etc/hosts hack))"
export crc_ip=$(192.168.130.11)
go install github.com/txn2/txeh/txeh@v1.5.4
sudo $(which txeh) add "$crc_ip" hello-world.info
cat /etc/hosts | grep hello-world.info

ink "access the application via ingress"
set -x
curl -k https://hello-world.info
