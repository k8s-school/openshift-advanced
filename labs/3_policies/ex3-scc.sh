#!/bin/sh

DIR=$(cd "$(dirname "$0")"; pwd -P)

EX3_SCC_FULL="${EX3_SCC_FULL:-false}"

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

set -eux

ID=0
NS="scc-example-$ID"
SA="fake-user"

# See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#run-another-pod
kubectl delete namespace -l "scc=true"
oc adm policy remove-scc-from-user anyuid -z $SA || echo "WARN: anyuid not allowed to $SA"
oc adm policy remove-scc-from-user hostpath-provisioner -z $SA || echo "WARN: hostpath-provisioner not allowed to $SA"
oc adm policy remove-scc-from-user hostpath-provisioner -z default || echo "WARN: hostpath-provisioner not allowed to default"

oc new-project "$NS"
kubectl label ns "$NS" "scc=true"
kubectl create serviceaccount -n "$NS" $SA

# WARN alias does not work with bash
alias kubectl-admin='kubectl -n "$NS"'
alias kubectl-user='kubectl --as=system:serviceaccount:$NS:$SA -n "$NS"'

cat <<EOF > /tmp/ubuntu-root.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-root
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        runAsUser: 0
EOF

cat <<EOF > /tmp/ubuntu-simple.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-simple
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
EOF

cat <<EOF > /tmp/ubuntu-privileged.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-privileged
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        privileged: true
EOF

cat <<EOF > /tmp/nginx-privileged.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-privileged
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
EOF

if [ "$EX3_SCC_FULL" = false ]
then
    exit 0
fi

green "Allow fake-user to create pods and deployments only in $NS"
kubectl create rolebinding -n "$NS" edit --clusterrole=edit --serviceaccount="$NS":$SA

green "Try to create pod ubuntu-simple"
kubectl-user create -f /tmp/ubuntu-simple.yaml

green "Check access to scc"
kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/restricted-v2

green "Check which scc was used"
kubectl get pod ubuntu-simple -o yaml | grep -i runasuser
kubectl get pod ubuntu-simple -o yaml | grep -i scc

green "Show which SCC is required by the pod ubuntu-simple"
green "WARN: command should not display anyuid here: inconsistency"
oc adm policy scc-subject-review -f /tmp/ubuntu-simple.yaml

green "Try to create pod ubuntu-root"
if kubectl-user create -f /tmp/ubuntu-root.yaml
then
    red "ERROR: User '$SA' should not be able to create pod ubuntu root"
    exit 1
else
    yellow "EXPECTED ERROR: User '$SA' cannot create pod"
fi

green "Get scc for pod ubuntu-root"
oc adm policy scc-subject-review -f /tmp/ubuntu-root.yaml

green "Check access to scc"
if kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/anyuid
then
    >&2 echo "ERROR: User '$SA' should not be able to use scc/anyuid"
    exit 1
else
    yellow "EXPECTED ERROR: User '$SA' cannot use scc/anyuid"
fi

# kubectl-admin create role scc:anyuid \
#    --verb=use \
#    --resource=scc \
#    --resource-name=anyuid

green "Grant access to scc anyuid to service account $SA"
# WARN: it edits a clusterrolebinding
oc adm policy add-scc-to-user anyuid -z $SA

green "Check if service account can create pod ubuntu-root"
oc adm policy scc-review -z system:serviceaccount:"$NS":$SA -f /tmp/ubuntu-root.yaml

green "Create pod ubuntu-root"
kubectl-user create -f /tmp/ubuntu-root.yaml

if kubectl-user create -f /tmp/ubuntu-privileged
then
    red "ERROR: User '$SA' should not be able to create privileged pod"
    exit 1
else
    yellow "EXPECTED ERROR: User '$SA' cannot create privileged pod"
fi

green "Show which SCC is required by the pod ubuntu-privileged"
oc adm policy scc-subject-review  -f /tmp/ubuntu-privileged.yaml

green "Grant access to scc hostpath-provisioner to service account $SA"
oc adm policy add-scc-to-user hostpath-provisioner -z $SA

green "Create pod ubuntu-privileged"
kubectl-user create -f /tmp/ubuntu-privileged.yaml

kubectl-user apply -f /tmp/nginx-privileged.yaml
kubectl-user get pods
kubectl-user get events | head -n 2
oc adm policy add-scc-to-user hostpath-provisioner -z default


# Wait for deployment to recreate the pod
sleep 5
kubectl wait --timeout=60s --for=condition=Ready pods -l app=nginx -n "$NS"
kubectl-user get pods


