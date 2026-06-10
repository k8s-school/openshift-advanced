#!/bin/bash
# Airgapped deployment — Approach A variant: mirroring via `oc mirror` v2 instead of skopeo.
# Advantage over skopeo: one config file, state tracking between runs (delta only),
# scales to dozens of images + operator catalogs in a single pass.
# Run prereqs-registry.sh first (local registry + insecureRegistries patch).

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

ID="$(whoami)"
NS="airgapped-$ID"
RELEASE="nginx"
# IP de l'hôte sur le bridge libvirt (virbr0), accessible depuis la VM CRC
HOST_IP=$(ip -4 addr show virbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
LOCAL_REGISTRY="${HOST_IP}:5000"
MIRROR_WORKSPACE="/tmp/oc-mirror-workspace"

ink "Mirror nginx + alpine images via oc mirror (declarative, delta-aware)"
mkdir -p "$MIRROR_WORKSPACE"
export NGINX_VERSION ALPINE_VERSION
envsubst < "$DIR/manifests/imageset-config.yaml" > /tmp/imageset-config.yaml
oc mirror -c /tmp/imageset-config.yaml \
    --workspace "file://$MIRROR_WORKSPACE" \
    --dest-skip-tls \
    "docker://$LOCAL_REGISTRY"

ink "Apply ImageTagMirrorSet so cluster nodes redirect docker.io → $LOCAL_REGISTRY (tag-based pulls)"
export HOST_IP
envsubst < "$DIR/manifests/image-tag-mirror-set.yaml" | kubectl apply -f -

ink "Wait for MachineConfigPool worker to apply the new mirror config"
oc wait machineconfigpool/worker \
    --for=condition=Updated \
    --timeout=300s

kubectl delete ns -l "airgapped=$ID" --ignore-not-found
oc new-project "$NS"
kubectl label ns "$NS" "airgapped=$ID"
kubectl config set-context --current --namespace="$NS"

ink "Install local nginx chart with mirror=true (nginx + alpine sidecar, both pulled from mirror)"
helm install "$RELEASE" "$DIR/../nginx-chart" \
    --namespace "$NS" \
    --values "$DIR/../6_helm_migration/manifests/nginx-values-v2.yaml" \
    --set image.pullPolicy=Always \
    --set sidecar.image.pullPolicy=Always \
    --set mirror=true \
    --set sidecar.image.tag="$ALPINE_VERSION" \
    --wait --timeout 120s

ink "Verify both containers are running"
kubectl get pod -l "app=$RELEASE" -o jsonpath='{range .items[0].spec.containers[*]}{.name}: {.image}{"\n"}{end}'
kubectl describe pod -l "app=$RELEASE" | grep -A10 "Events:"

ink "Verify both images were pulled from local registry"
podman logs local-registry 2>&1 | grep GET
