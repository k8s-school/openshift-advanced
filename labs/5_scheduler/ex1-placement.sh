#!/bin/bash

# Scheduler Lab 1 - Pod placement: affinity, anti-affinity, taints
# Validate the solutions of https://k8s-school.fr/labs/k8s/en/1_labs/antiaffinity/index.html
# Works on Kubernetes and OpenShift, requires cluster-admin and 3 worker nodes.
#
# The cluster can be shared by several trainees:
# - the infra node (label and taint 'dedicated=infra') is shared: the first run creates it, the others check it
# - the node label of exercise 2 is per trainee: 'disk-<id>=ssd'
# - NoExecute taints evict the pods of all trainees: they run only in trainer mode (-s)

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$DIR/../conf.version.sh"

IMAGE="nginxinc/nginx-unprivileged:${NGINX_UNPRIVILEGED_VERSION}"

ID="${ID:-$(whoami)}"
NS="placement-$ID"
SSD_LABEL="disk-$ID"
TRAINER=false
CLEANUP=false

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h         this message
    -s         trainer mode, also run the NoExecute demo (evicts the pods of all trainees)
    -c         trainer mode, remove the shared infra node setup and exit

Run pod placement exercise
EOD
}

# get the options
while getopts hsc c ; do
    case $c in
	    h) usage ; exit 0 ;;
	    s) TRAINER=true ;;
	    c) CLEANUP=true ;;
	    \?) usage ; exit 2 ;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

WORKERS=($(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort))
if [ ${#WORKERS[@]} -lt 3 ]; then
    ink -r "At least 3 worker nodes are required, found ${#WORKERS[@]}"
    exit 1
fi

if [ "$CLEANUP" = true ]; then
    for node in "${WORKERS[@]}"; do
        kubectl taint node "$node" dedicated- 2>/dev/null || true
        kubectl taint node "$node" maintenance- 2>/dev/null || true
        kubectl label node "$node" dedicated- 2>/dev/null || true
    done
    exit 0
fi

# Create a node label, or check it already has the expected value
ensure_label() {
    local node="$1" key="$2" value="$3"
    kubectl label node "$node" "$key=$value" 2>/dev/null || true
    local current=$(kubectl get node "$node" -o jsonpath="{.metadata.labels.$key}")
    if [ "$current" != "$value" ]; then
        ink -r "Node $node has label $key=$current, expected $value"
        exit 1
    fi
}

# Create a node taint, or check it already has the expected value
ensure_taint() {
    local node="$1" key="$2" value="$3" effect="$4"
    kubectl taint node "$node" "$key=$value:$effect" 2>/dev/null || true
    local current=$(kubectl get node "$node" -o jsonpath="{.spec.taints[?(@.key==\"$key\")].value}:{.spec.taints[?(@.key==\"$key\")].effect}")
    if [ "$current" != "$value:$effect" ]; then
        ink -r "Node $node has taint $key=$current, expected $value:$effect"
        exit 1
    fi
}

# Shared setup: reuse the infra node if it exists, else reserve the last worker
INFRA_NODE=$(kubectl get nodes -l dedicated=infra -o jsonpath='{.items[*].metadata.name}')
INFRA_NODE=${INFRA_NODE:-${WORKERS[-1]}}
ensure_label "$INFRA_NODE" dedicated infra
ensure_taint "$INFRA_NODE" dedicated infra NoSchedule

# Workers available for pods without toleration
USABLE=()
for node in "${WORKERS[@]}"; do
    [ "$node" != "$INFRA_NODE" ] && USABLE+=("$node")
done
SSD_NODE=${USABLE[0]}

cleanup() {
    kubectl delete ns "$NS" --ignore-not-found
    kubectl label node "$SSD_NODE" "$SSD_LABEL-" 2>/dev/null || true
}
trap cleanup EXIT

kubectl delete ns "$NS" --ignore-not-found
kubectl create namespace "$NS"

# Wait until a command output equals the expected value
# $1: expected value, $2: timeout in seconds, $3...: command
wait_for() {
    local expected="$1" timeout="$2"
    shift 2
    local deadline=$((SECONDS + timeout))
    until [ "$("$@")" = "$expected" ]; do
        if [ $SECONDS -ge $deadline ]; then
            ink -r "Timeout: expected '$expected', got '$("$@")'"
            exit 1
        fi
        sleep 5
    done
}

# Number of pods of an app in a given phase
count_pods() {
    kubectl get pods -n "$NS" -l app="$1" --field-selector=status.phase="$2" --no-headers 2>/dev/null | wc -l
}

# Sorted unique list of nodes running the pods of an app
pod_nodes() {
    kubectl get pods -n "$NS" -l app="$1" --field-selector=status.phase=Running \
        -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u | xargs
}

# Number of distinct nodes running the pods of an app
count_nodes() {
    pod_nodes "$1" | wc -w
}

# Space-separated names of the running pods of an app
pod_names() {
    kubectl get pods -n "$NS" -l app="$1" --field-selector=status.phase=Running \
        -o jsonpath='{.items[*].metadata.name}'
}

deployment() {
    local name="$1" replicas="$2" spec="$3"
    cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $NS
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
    spec:
$spec
      containers:
      - name: nginx
        image: $IMAGE
        ports:
        - containerPort: 8080
EOF
}

# The current context is shared by trainees running from the same account: always set the namespace
k() {
    kubectl -n "$NS" "$@"
}

# ---------------------------------------------------------------------------
# Exercise 1: pod anti-affinity
# ---------------------------------------------------------------------------
ink "Exercise 1: pod anti-affinity"
deployment nginx 2 "" | kubectl apply -f -
k rollout status deployment nginx --timeout=120s

# Re-create the Deployment, a rolling update would block on the anti-affinity
k delete deployment nginx --wait
deployment nginx 2 "      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - nginx
            topologyKey: kubernetes.io/hostname" | kubectl apply -f -
k rollout status deployment nginx --timeout=120s
k get pods -o wide
[ "$(count_nodes nginx)" -eq 2 ] || { ink -r "nginx pods are not on 2 different nodes"; exit 1; }

# The anti-affinity only applies to pods of the same namespace, other trainees do not interfere
k scale deployment nginx --replicas=4
wait_for 2 60 count_pods nginx Pending
k get pods -o wide
k get events --field-selector=reason=FailedScheduling | grep -q "anti-affinity" || \
    { ink -r "No FailedScheduling event about anti-affinity"; exit 1; }
k delete deployment nginx --wait
ink "Exercise 1: success"

# ---------------------------------------------------------------------------
# Exercise 2: node affinity
# ---------------------------------------------------------------------------
ink "Exercise 2: node affinity"
kubectl label node "$SSD_NODE" "$SSD_LABEL=ssd" --overwrite
deployment nginx-ssd 3 "      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: $SSD_LABEL
                operator: In
                values:
                - ssd" | kubectl apply -f -
k rollout status deployment nginx-ssd --timeout=120s
k get pods -l app=nginx-ssd -o wide
[ "$(pod_nodes nginx-ssd)" = "$SSD_NODE" ] || { ink -r "nginx-ssd pods are not all on $SSD_NODE"; exit 1; }

# Running pods stay, new pods stay Pending
kubectl label node "$SSD_NODE" "$SSD_LABEL-"
k rollout restart deployment nginx-ssd
wait_for 1 60 count_pods nginx-ssd Pending
k get pods -l app=nginx-ssd -o wide
[ "$(count_pods nginx-ssd Running)" -eq 3 ] || { ink -r "Running nginx-ssd pods were evicted"; exit 1; }
k delete deployment nginx-ssd --wait
ink "Exercise 2: success"

# ---------------------------------------------------------------------------
# Exercise 3: taints and tolerations
# ---------------------------------------------------------------------------
ink "Exercise 3: taints and tolerations"
k create deployment nginx --image="$IMAGE" --replicas=6
k rollout status deployment nginx --timeout=120s
k get pods -l app=nginx -o wide
pod_nodes nginx | grep -qw "$INFRA_NODE" && { ink -r "nginx pods run on tainted node $INFRA_NODE"; exit 1; }

INFRA_TOLERATION="      tolerations:
      - key: dedicated
        operator: Equal
        value: infra
        effect: NoSchedule"
INFRA_AFFINITY="      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: dedicated
                operator: In
                values:
                - infra"
deployment infra 2 "$INFRA_TOLERATION
$INFRA_AFFINITY" | kubectl apply -f -
k rollout status deployment infra --timeout=120s
k get pods -l app=infra -o wide
[ "$(pod_nodes infra)" = "$INFRA_NODE" ] || { ink -r "infra pods are not all on $INFRA_NODE"; exit 1; }
ink "Exercise 3: success"

if [ "$TRAINER" = false ]; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Trainer demo: NoExecute taints, they evict the pods of all trainees
# ---------------------------------------------------------------------------
ink "Trainer demo: NoExecute"
MAINTENANCE_NODE=${USABLE[1]}
kubectl taint node "$MAINTENANCE_NODE" maintenance=true:NoExecute
wait_for 0 120 sh -c "kubectl get pods -n '$NS' -l app=nginx -o wide --no-headers | grep -cw '$MAINTENANCE_NODE' || true"
k rollout status deployment nginx --timeout=120s
k get pods -l app=nginx -o wide

# Tolerate the maintenance taint for 60 seconds
deployment infra 2 "$INFRA_TOLERATION
      - key: maintenance
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 60
$INFRA_AFFINITY" | kubectl apply -f -
k rollout status deployment infra --timeout=120s
# Wait for the old pods to be gone, terminating pods are still in Running phase
wait_for 2 60 sh -c "kubectl get pods -n '$NS' -l app=infra --no-headers | wc -l"
INFRA_PODS=$(pod_names infra)
kubectl taint node "$INFRA_NODE" maintenance=true:NoExecute
sleep 30
[ "$(pod_names infra)" = "$INFRA_PODS" ] || { ink -r "infra pods evicted before tolerationSeconds"; exit 1; }
# Evicted after 60s, then scheduled again on $INFRA_NODE
deadline=$((SECONDS + 90))
until [ "$(pod_names infra)" != "$INFRA_PODS" ] && [ "$(count_pods infra Running)" -eq 2 ]; do
    [ $SECONDS -ge $deadline ] && { ink -r "infra pods not evicted after tolerationSeconds"; exit 1; }
    sleep 5
done
k get pods -l app=infra -o wide
[ "$(pod_nodes infra)" = "$INFRA_NODE" ] || { ink -r "infra pods not rescheduled on $INFRA_NODE"; exit 1; }

kubectl taint node "$MAINTENANCE_NODE" maintenance-
kubectl taint node "$INFRA_NODE" maintenance-
ink "Trainer demo: success"
