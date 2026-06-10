#!/bin/bash
# Airgapped deployment — Approach A: transparent mirroring with ImageTagMirrorSet.
# Run prereqs-registry.sh first (local registry + insecureRegistries patch).

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

ID="$(whoami)"
NS="airgapped-$ID"
RELEASE="nginx-mirror"
# IP de l'hôte sur le bridge libvirt (virbr0), accessible depuis la VM CRC
HOST_IP=$(ip -4 addr show virbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
LOCAL_REGISTRY="${HOST_IP}:5000"

ink "Mirror nginx image into local registry, preserving docker.io's implicit library/ namespace"
skopeo copy \
    "docker://docker.io/nginx:$NGINX_VERSION" \
    "docker://$LOCAL_REGISTRY/library/nginx:$NGINX_VERSION" \
    --dest-tls-verify=false

ink "Apply ImageTagMirrorSet so cluster nodes redirect docker.io → $LOCAL_REGISTRY (tag-based pulls)"
cat <<EOF | kubectl apply -f -
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: local-registry-mirror
spec:
  imageTagMirrors:
  - mirrors:
    - ${HOST_IP}:5000
    source: docker.io
    mirrorSourcePolicy: NeverContactSource
EOF

ink "Wait for MachineConfigPool worker to apply the new mirror config"
oc wait machineconfigpool/worker \
    --for=condition=Updated \
    --timeout=300s

ink "Verify registries.conf was updated on a worker node"
WORKER=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}')
oc debug node/$WORKER -- chroot /host cat /etc/containers/registries.conf

kubectl delete ns -l "airgapped=$ID" --ignore-not-found
oc new-project "$NS"
kubectl label ns "$NS" "airgapped=$ID"
kubectl config set-context --current --namespace="$NS"

ink "Install nginx chart unchanged — ImageTagMirrorSet redirects docker.io → $LOCAL_REGISTRY transparently"
helm install "$RELEASE" "$DIR/../nginx-chart" \
    --namespace "$NS" \
    --values "$DIR/../6_helm_migration/manifests/nginx-values-v2.yaml" \
    --set image.pullPolicy=Always \
    --wait --timeout 120s

ink "Verify pod image reference is unchanged (still nginx:$NGINX_VERSION) — pull came from the mirror transparently"
kubectl get pod -l "app=$RELEASE" -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
kubectl describe pod -l "app=$RELEASE" | grep -A6 "Events:"
podman logs local-registry 2>&1 | grep GET
