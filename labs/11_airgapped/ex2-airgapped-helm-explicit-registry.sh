#!/bin/bash
# Airgapped deployment using explicit registry in Helm chart values.
# No ImageDigestMirrorSet, no MachineConfigPool wait.

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

ID="$(whoami)"
NS="airgapped-$ID"
RELEASE="nginx"
# IP de l'hôte sur le bridge libvirt (virbr0), accessible depuis la VM CRC
HOST_IP=$(ip -4 addr show virbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
LOCAL_REGISTRY="${HOST_IP}:5000"
NGINX_IMAGE="docker.io/nginx:$NGINX_VERSION"

ink "Start local registry on 0.0.0.0:5000"
sudo podman rm -f local-registry 2>/dev/null || true
sudo podman run -d --name local-registry -p 5000:5000 \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2

ink "Mirror nginx image into local registry"
skopeo copy \
    "docker://$NGINX_IMAGE" \
    "docker://$LOCAL_REGISTRY/nginx:$NGINX_VERSION" \
    --dest-tls-verify=false

ink "Allow insecure HTTP access to local registry on cluster nodes"
oc patch image.config.openshift.io/cluster --type=merge \
    -p "{\"spec\":{\"registrySources\":{\"insecureRegistries\":[\"$LOCAL_REGISTRY\"]}}}"

ink "Wait for MachineConfigPool worker to apply insecure registry config"
oc wait machineconfigpool/worker \
    --for=condition=Updated \
    --timeout=300s

kubectl delete ns -l "airgapped=$ID" --ignore-not-found
oc new-project "$NS"
kubectl label ns "$NS" "airgapped=$ID"
kubectl config set-context --current --namespace="$NS"

ink "Install local nginx chart with explicit registry — no ImageDigestMirrorSet"
helm install "$RELEASE" "$DIR/../nginx-chart" \
    --namespace "$NS" \
    --values "$DIR/../6_helm_migration/manifests/nginx-values-v2.yaml" \
    --set image.registry="$LOCAL_REGISTRY" \
    --set image.pullPolicy=IfNotPresent \
    --wait --timeout 120s

ink "Verify pod uses the explicit local registry image"
kubectl get pod -l "app=$RELEASE" -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
kubectl describe pod -l "app=$RELEASE" | grep -A5 "Events:"
sudo podman logs local-registry 2>&1 | grep GET
