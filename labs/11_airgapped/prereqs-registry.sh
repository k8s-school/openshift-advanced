#!/bin/bash
# Pre-requisite for the airgapped lab — start a local mirror registry reachable
# from the cluster, and allow cluster nodes to pull from it over plain HTTP.
# Run this once, before ex1/ex2/ex3. It is shared infrastructure: do not rerun
# it between exercises.

set -euxo pipefail

# IP de l'hôte sur le bridge libvirt (virbr0), accessible depuis la VM CRC
HOST_IP=$(ip -4 addr show virbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
REGISTRY_PORT=5000
LOCAL_REGISTRY="${HOST_IP}:$REGISTRY_PORT"

ink "Start local registry on 0.0.0.0:$REGISTRY_PORT"
podman rm -f local-registry 2>/dev/null || true
podman run -d --name local-registry -p $REGISTRY_PORT:$REGISTRY_PORT \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2

ink "Allow insecure HTTP access to local registry on cluster nodes"
oc patch image.config.openshift.io/cluster --type=merge \
    -p "{\"spec\":{\"registrySources\":{\"insecureRegistries\":[\"$LOCAL_REGISTRY\"]}}}"

ink "Wait for MachineConfigPool worker to apply insecure registry config"
oc wait machineconfigpool/worker \
    --for=condition=Updated \
    --timeout=300s
