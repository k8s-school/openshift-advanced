#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

ID="$(whoami)"
RELEASE="nginx"
CHART="$DIR/nginx-chart"

pause() {
    [ "${INTERACTIVE:-true}" = "false" ] && return
    echo ""
    read -rp ">>> [Step $1] Press Enter to continue... " _
    echo ""
}

usage() {
    echo "Usage: $0 [-c] [-y]"
    echo "  -c  Use current namespace instead of creating a new one"
    echo "  -y  Non-interactive mode (skip pause between steps)"
    exit 1
}

USE_CURRENT_NS=false
while getopts "cy" opt; do
    case $opt in
        c) USE_CURRENT_NS=true ;;
        y) INTERACTIVE=false ;;
        *) usage ;;
    esac
done

if [ "$USE_CURRENT_NS" = "true" ]; then
    NS=$(kubectl config view --minify -o jsonpath='{..namespace}')
    echo "Using current namespace: $NS"
else
    NS="helm-migration-$ID"
    kubectl delete ns -l "helm-migration=$ID" --ignore-not-found
    oc new-project "$NS"
    kubectl label ns "$NS" "helm-migration=$ID"
    kubectl config set-context --current --namespace="$NS"
fi

# STEP 0 — Helm defaults: LoadBalancer + port 80
##################################################

ink "Step 0 — Install nginx with Helm defaults (LoadBalancer + port 80)"
ink "Expected failure: LoadBalancer quota on Red Hat Developer Portal (services.loadbalancers=0)"
if helm upgrade --install "$RELEASE" "$CHART" \
    --namespace "$NS" \
    --set image.tag="$NGINX_VERSION" \
    --wait --timeout 30s
then
    ink -r "Unexpected success: LoadBalancer quota should have blocked this"
    exit 1
else
    ink "Expected failure confirmed"
fi

ink -y "Diagnose step 0: quota limits + events"
# ClusterResourceQuota is enforced at cluster level per user, not per namespace
# kubectl get resourcequota only shows namespace-scoped quotas — misses cluster-level ones
oc get appliedclusterresourcequota
SERVICES_QUOTA=$(oc get appliedclusterresourcequota -o name | grep "\-services$" | cut -d/ -f2)
oc describe appliedclusterresourcequota "$SERVICES_QUOTA"
# The quota violation is rejected by the admission controller before the resource is persisted
# → no Kubernetes Event is generated for it; the error is returned directly to the helm client
# Events below only reflect resources that passed admission (Deployment, ReplicaSet, Pod)
kubectl get events --sort-by='.lastTimestamp' | tail -20

pause 0

# STEP 1 — ClusterIP: fixes quota, still fails on SCC (port 80 = root)
########################################################################

ink "Step 1 — ClusterIP service (fixes LoadBalancer quota)"
ink "Expected failure: nginx runs as root on port 80, blocked by restricted-v2 SCC"
if helm upgrade --install "$RELEASE" "$CHART" \
    --namespace "$NS" \
    --values "$DIR/manifests/nginx-values-v1.yaml" \
    --set image.tag="$NGINX_VERSION" \
    --wait --timeout 30s
then
    ink -r "Unexpected success: SCC should have blocked port 80"
    exit 1
else
    ink "Expected failure confirmed"
fi

ink -y "Diagnose step 1: events"
kubectl get events --sort-by='.lastTimestamp' | tail -20

ink -y "Diagnose step 1: SCC — UID range assigned by OpenShift to the namespace"
# OpenShift annotates each namespace with the allowed UID range (e.g. 1000650000/10000)
# Every container gets a UID from that range — never root (UID 0)
oc get namespace "$NS" \
    -o jsonpath='UID range: {.metadata.annotations.openshift\.io/sa\.scc\.uid-range}{"\n"}'

ink -y "Diagnose step 1: runAsUser of nginx pod containers"
# If runAsUser is empty, the image decides — official nginx starts as root (UID 0)
# OpenShift enforces a UID from the range above via the SCC — unavoidable conflict on port 80
kubectl get pod -l "app=$RELEASE" \
    -o jsonpath='{range .items[*]}{range .spec.containers[*]}  container={.name}  runAsUser={.securityContext.runAsUser}{"\n"}{end}{end}' \
    2>/dev/null || echo "  (no pod found or runAsUser not set)"

ink -y "Diagnose step 1: pod status + nginx logs (nginx startup forbidden without root)"
echo "Waiting for pod crash..."
TRIES=0
until oc get pods -l "app=$RELEASE" --no-headers 2>/dev/null \
        | grep -qE "CrashLoopBackOff|Error|OOMKilled"; do
    echo -n "."
    sleep 3
    TRIES=$((TRIES + 1))
    [ $TRIES -ge 20 ] && echo " (timeout — pod still starting)" && break
done
echo
oc get pods -l "app=$RELEASE"
oc logs -l "app=$RELEASE" --tail=30 2>&1 || true
kubectl describe pod -l "app=$RELEASE" -n "$NS" | grep -A 20 "Events:" || true

if oc auth can-i create podsecuritypolicyselfsubjectreviews.security.openshift.io --namespace "$NS" &>/dev/null; then
    oc adm policy scc-subject-review -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-probe
spec:
  containers:
  - name: nginx
    image: nginx:$NGINX_VERSION
    ports:
    - containerPort: 80
EOF
else
    echo "INFO: skipping scc-subject-review (insufficient rights on the Red Hat Developer Portal)"
fi

pause 1

# STEP 2 — OpenShift-compatible: port 8080 + security context + custom nginx.conf
##################################################################################

ink "Step 2 — OpenShift-compatible (port 8080 + security context + custom nginx.conf)"
helm upgrade --install "$RELEASE" "$CHART" \
    --namespace "$NS" \
    --values "$DIR/manifests/nginx-values-v2.yaml" \
    --set image.tag="$NGINX_VERSION" \
    --wait --timeout 60s

kubectl get pods -n "$NS"
kubectl get pod -l "app=$RELEASE" -o jsonpath='{.items[0].metadata.annotations.openshift\.io/scc}' && echo
