#!/bin/bash

## Install prometheus stack

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NS="monitoring"

# TODO hack, implement nicely helm delete
helm delete prometheus-stack -n monitoring || ink "Unable to delete prometheus stack"

kubectl delete ns -l name="$NS"
kubectl create namespace "$NS"
kubectl label ns "$NS" "name=$NS"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || ink "Unable to add repo prometheus-community"
helm repo add stable https://charts.helm.sh/stable --force-update
helm repo update
helm install --version "45.27.2" prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring  -f "$DIR"/values.yaml --create-namespace

ink "Exercice: access prometheus-grafana and other services using the website documentation"
ink "1. Watch all pod in monitoring namespace"
ink "2. Retrieve grafana password using 'helm show values prometheus-community/kube-prometheus-stack'"
ink "3. Port forward grafana and access it in a web browser"
