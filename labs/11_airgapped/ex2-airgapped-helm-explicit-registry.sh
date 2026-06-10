#!/bin/bash
# Airgapped deployment — Approach B: explicit registry reference in chart values.
# No ImageTagMirrorSet involved. Run after ex1-airgapped-helm.sh (reuses its namespace).
# Run prereqs-registry.sh first (local registry + insecureRegistries patch).

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

ID="$(whoami)"
NS="airgapped-$ID"
RELEASE="nginx-explicit"
# IP de l'hôte sur le bridge libvirt (virbr0), accessible depuis la VM CRC
HOST_IP=$(ip -4 addr show virbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
LOCAL_REGISTRY="${HOST_IP}:5000"

ink "Mirror nginx image into local registry, at a path of our own choosing (no library/ needed)"
skopeo copy \
    "docker://docker.io/nginx:$NGINX_VERSION" \
    "docker://$LOCAL_REGISTRY/nginx:$NGINX_VERSION" \
    --dest-tls-verify=false

kubectl config set-context --current --namespace="$NS"

ink "Install nginx chart with explicit registry — no ImageTagMirrorSet redirection involved"
helm install "$RELEASE" "$DIR/../nginx-chart" \
    --namespace "$NS" \
    --values "$DIR/../6_helm_migration/manifests/nginx-values-v2.yaml" \
    --set image.registry="$LOCAL_REGISTRY" \
    --set image.pullPolicy=IfNotPresent \
    --wait --timeout 120s

ink "Verify pod image reference explicitly shows the local registry — no redirection magic"
kubectl get pod -l "app=$RELEASE" -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
kubectl describe pod -l "app=$RELEASE" | grep -A5 "Events:"
podman logs local-registry 2>&1 | grep GET
