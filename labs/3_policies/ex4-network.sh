#!/bin/bash

set -euxo pipefail
shopt -s expand_aliases

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

EX4_NETWORK_FULL="${EX4_NETWORK_FULL:-false}"


ID="$USER"
NS="network-$ID"

NODE1_IP=$(kubectl get nodes --selector="node-role.kubernetes.io/control-plane=" \
    -o=jsonpath='{.items[0].status.addresses[0].address}')

# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete ns -l "kubernetes.io/metadata.name=$NS"
kubectl create namespace "$NS"

ink -b 'Exercice: Install one postgresql pod with helm and add label "tier:database" to master pod'
ink "Disable data persistence"
helm delete pgsql --namespace "$NS" || ink -y "WARN pgsql release not found"

helm repo add bitnami https://charts.bitnami.com/bitnami || ink "Failed to add bitnami repo"
helm repo update

helm install --version 11.9.1 --namespace "$NS" pgsql bitnami/postgresql --set primary.podLabels.tier="database",persistence.enabled="false"

ink "Install nginx pods"
kubectl run -n "$NS" external --image=nginx:$NGINX_VERSION -l "app=external"
kubectl run -n "$NS" nginx --image=nginx:$NGINX_VERSION -l "tier=webserver"

kubectl wait --timeout=60s -n "$NS" --for=condition=Ready pods external

kubectl expose -n "$NS" pod external --type=NodePort --port 80 --name=external
ink "Install netcat, ping, netstat and ps in these pods"
kubectl exec -n "$NS" -it external -- \
    sh -c "apt-get update && apt-get install -y dnsutils inetutils-ping netcat-traditional net-tools procps tcpdump"

kubectl wait --timeout=60s -n "$NS" --for=condition=Ready pods nginx
kubectl exec -n "$NS" -it nginx -- \
    sh -c "apt-get update && apt-get install -y dnsutils inetutils-ping netcat-traditional net-tools procps tcpdump"

ink "Wait for pgsql pods to be ready"
kubectl wait --for=condition=Ready -n "$NS" pods -l app.kubernetes.io/instance=pgsql

ink "then check what happen with no network policies defined"
ink "++++++++++++++++++++"
ink "NO NETWORK POLICIES"
ink "++++++++++++++++++++"
EXTERNAL_IP=$(kubectl get pods -n "$NS" external -o jsonpath='{.status.podIP}')
PGSQL_IP=$(kubectl get pods -n "$NS" pgsql-postgresql-0 -o jsonpath='{.status.podIP}')
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv ${PGSQL_IP} 5432
kubectl exec -n "$NS" nginx -- netcat -q 2 -zv pgsql-postgresql 5432
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv $EXTERNAL_IP 80
kubectl exec -n "$NS" external -- netcat -w 2 -zv www.k8s-school.fr 443

ink "EXERCICE: Secure communication between webserver and database, and test (webserver, database, external, outside)"

if [ "$EX4_NETWORK_FULL" = false ]
then
    exit 0
fi

ink "Enable DNS access, see https://docs.projectcalico.org/v3.7/security/advanced-policy#5-allow-dns-egress-traffic"
kubectl apply -n "$NS" -f $DIR/resource/allow-dns-access.yaml

# Edit original file, replace app with tier
kubectl apply -n "$NS" -f $DIR/resource/ingress-www-db.yaml
# Edit original file, replace app with tier
kubectl apply -n "$NS" -f $DIR/resource/egress-www-db.yaml
ink "Set default deny network policies"
# See https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-policies
kubectl apply -n "$NS" -f $DIR/resource/default-deny.yaml

ink "Play and test network connections after each step"
ink "+---------------------+"
ink "WITH NETWORK POLICIES"
ink "+---------------------+"
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv ${PGSQL_IP} 5432
kubectl exec -n "$NS" nginx -- netcat -w 2 -nzv $EXTERNAL_IP 80 && ink -r "ERROR this command should have failed"
kubectl exec -n "$NS" external -- netcat -w 2 -zv pgsql-postgresql 5432 && ink -r "ERROR this command should have failed"
kubectl exec -n "$NS" external -- netcat -w 2 -zv www.k8s-school.fr 80 && ink -r "ERROR this command should have failed"
# Ip for www.w3.org
kubectl exec -n "$NS" external -- netcat -w 2 -nzv 128.30.52.100 80 && ink -r "ERROR this command should have failed"

