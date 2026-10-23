#!/bin/bash
# Pre-requisite for the airgapped lab — start a local mirror registry reachable
# from the cluster, and allow cluster nodes to pull from it over plain HTTP.
# Run this once, before ex1/ex2/ex3. It is shared infrastructure: do not rerun
# it between exercises.

set -euxo pipefail

# Host IP on the libvirt bridge of the CRC VM: 'crc' (network-mode system) or virbr0
HOST_IP=$({ ip -4 -o addr show crc; ip -4 -o addr show virbr0; } 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
REGISTRY_PORT=5000
LOCAL_REGISTRY="${HOST_IP}:$REGISTRY_PORT"

ink "Start local registry on $LOCAL_REGISTRY"
podman rm -f local-registry 2>/dev/null || true
podman run -d --name local-registry -p $HOST_IP:$REGISTRY_PORT:$REGISTRY_PORT \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2

ink "Allow insecure HTTP access to local registry on cluster nodes"
oc patch image.config.openshift.io/cluster --type=merge \
    -p "{\"spec\":{\"registrySources\":{\"insecureRegistries\":[\"$LOCAL_REGISTRY\"]}}}"

# Poll the node file: on CRC the worker pool has no machine and is always Updated
ink "Wait for the insecure registry config to reach the node"
NODE=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}')
until oc debug node/$NODE -- chroot /host cat /etc/containers/registries.conf | grep -q "$HOST_IP"; do
    sleep 5
done
