#!/bin/bash

# See https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-36475925a560

set -euxo pipefail

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function red {
    set +x
    >&2 printf "${RED}$@${NC}\n"
    set -x
}

function green {
    set +x
    printf "${GREEN}$@${NC}\n"
    set -x
}

function yellow {
    set +x
    printf "${YELLOW}$@${NC}\n"
    set -x
}

DIR=$(cd "$(dirname "$0")"; pwd -P)
EX4_NETWORK_FULL="${EX4_NETWORK_FULL:-false}"

ID=0
NS="network-$ID"

NODE1_IP=$(kubectl get nodes --selector="node-role.kubernetes.io/master" \
    -o=jsonpath='{.items[0].status.addresses[0].address}')

# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete ns -l "policies=$NS"
kubectl create namespace "$NS"
kubectl label ns "$NS" "policies=$NS"

green "Install one postgresql pod with helm and add label "tier:database" to master pod"
green "Disable data persistence"
helm delete pgsql --namespace "$NS" || ink -y "WARN pgsql release not found"

helm repo add bitnami https://charts.bitnami.com/bitnami || ink "Failed to add bitnami repo"
helm repo update

helm install --version 11.9.1 --namespace "$NS" pgsql bitnami/postgresql --set primary.podLabels.tier="database",persistence.enabled="false"

green "Install nginx pod external"
kubectl run -n "$NS" external --image=nginx -l "app=external"
green "Install nginx pod webserver"
kubectl run -n "$NS" nginx --image=nginx -l "tier=webserver"

kubectl wait --timeout=60s -n "$NS" --for=condition=Ready pods external

kubectl expose -n "$NS" pod external --type=NodePort --port 80 --name=external

green "Install netcat, ping, netstat and ps in these pods"
kubectl exec -n "$NS" -it external -- \
    sh -c "apt-get update && apt-get install -y dnsutils inetutils-ping netcat-traditional net-tools procps tcpdump"

kubectl wait --timeout=60s -n "$NS" --for=condition=Ready pods nginx
kubectl exec -n "$NS" -it nginx -- \
    sh -c "apt-get update && apt-get install -y dnsutils inetutils-ping netcat-traditional net-tools procps tcpdump"

green "Wait for pgsql pods to be ready"
kubectl wait --for=condition=Ready -n "$NS" pods -l app.kubernetes.io/instance=pgsql

# then check what happen with no network policies defined
red "-------------------"
red "NO NETWORK POLICIES"
red "-------------------"
EXTERNAL_IP=$(kubectl get pods -n "$NS" external -o jsonpath='{.status.podIP}')
PGSQL_IP=$(kubectl get pods -n "$NS" pgsql-postgresql-0 -o jsonpath='{.status.podIP}')
green "Try questions"
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv ${PGSQL_IP} 5432
kubectl exec -n "$NS" nginx -- netcat -q 2 -zv pgsql-postgresql 5432
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv $EXTERNAL_IP 80
kubectl exec -n "$NS" external -- netcat -w 2 -zv www.k8s-school.fr 443

green "EXERCICE: Secure communication between webserver and database, and test (webserver, database, external, outside)"

if [ "$EX4_NETWORK_FULL" = false ]
then
    exit 0
fi

# Enable DNS access, see https://docs.projectcalico.org/v3.7/security/advanced-policy#5-allow-dns-egress-traffic
kubectl apply -n "$NS" -f $DIR/resource/allow-dns-access.yaml

# Edit original file, replace app with tier
kubectl apply -n "$NS" -f $DIR/resource/ingress-www-db.yaml
# Edit original file, replace app with tier
kubectl apply -n "$NS" -f $DIR/resource/egress-www-db.yaml
# Set default deny network policies
# See https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-policies
kubectl apply -n "$NS" -f $DIR/resource/default-deny.yaml

# Play and test network connections after each step
ink "---------------------"
ink "WITH NETWORK POLICIES"
ink "---------------------"
kubectl exec -n "$NS" nginx -- netcat -q 2 -nzv ${PGSQL_IP} 5432
kubectl exec -n "$NS" nginx -- netcat -w 2 -nzv $EXTERNAL_IP 80 && ink -r "ERROR this command should have failed"
kubectl exec -n "$NS" external -- netcat -w 2 -zv pgsql-postgresql 5432 && ink -r "ERROR this command should have failed"
kubectl exec -n "$NS" external -- netcat -w 2 -zv www.k8s-school.fr 80 && ink -r "ERROR this command should have failed"
# Ip for www.w3.org
kubectl exec -n "$NS" external -- netcat -w 2 -nzv 128.30.52.100 80 && ink -r "ERROR this command should have failed"

