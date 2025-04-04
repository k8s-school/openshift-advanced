#!/bin/bash

set -euxo pipefail
shopt -s expand_aliases

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh


readonly DIR=$(cd "$(dirname "$0")"; pwd -P)

# See https://kubernetes.io/blog/2021/12/09/pod-security-admission-beta/#hands-on-demo for details

kubectl delete namespace -l "podsecurity=enabled"
NS="verify-pod-security"

ink "Confirm Pod Security is enabled v1"
# API_SERVER_POD=$(kubectl get pods -n openshift-kube-apiserver -l apiserver=true -o jsonpath='{.items[0].metadata.name}')
# kubectl -n openshift-kube-apiserver exec "$API_SERVER_POD" -t -- kube-apiserver -h | grep "default enabled plugins" | grep "PodSecurity"
kubectl -n kube-system exec kube-apiserver-kind-control-plane -t -- kube-apiserver -h | grep "default enabled plugins" | grep "PodSecurity"


ink "Confirm Pod Security is enabled v2"
kubectl create namespace "$NS"
kubectl label ns "$NS" "podsecurity=enabled"
kubectl label namespace "$NS" pod-security.kubernetes.io/enforce=restricted
# The following command does NOT create a workload (--dry-run=server)
kubectl -n "$NS" run test --dry-run=server --image=ubuntu:24.04 --privileged || ink -y "EXPECTED ERROR"
kubectl delete namespace "$NS"

kubectl create namespace "$NS"
kubectl label ns "$NS" "podsecurity=enabled"

ink "Enforces a \"restricted\" security policy and audits on restricted"
kubectl label --overwrite ns verify-pod-security \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted

# Next, try to deploy a privileged workload in the namespace.
if cat <<EOF | kubectl -n verify-pod-security apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-privileged
spec:
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      allowPrivilegeEscalation: true
EOF
then
    ink -r "ERROR: Should not be able to create privileged pod in namespace $NS"
    exit 1
else
    ink -y "EXPECTED ERROR: No able to create privileged pod in namespace $NS"
fi

ink "Enforces a \"privileged\" security policy and warns / audits on baseline"
kubectl label --overwrite ns verify-pod-security \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/warn=baseline \
  pod-security.kubernetes.io/audit=baseline

# Next, try to deploy a workload in the namespace.
# Note allowPrivilegeEscalation is allowed in baseline mode
cat <<EOF | kubectl -n verify-pod-security apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-allow-privilege-escalation
spec:
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      allowPrivilegeEscalation: true
EOF
alias kubectl-admin="kubectl -n $NS"

kubectl-admin get pods
kubectl-admin delete pod ubuntu-allow-privilege-escalation

# Baseline level and workload
# The baseline policy demonstrates sensible defaults while preventing common container exploits.

ink "Enforces a \"restricted\" security policy and audits on restricted"
kubectl label --overwrite ns verify-pod-security \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted

# Apply the workload.

if cat <<EOF | kubectl -n verify-pod-security apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-baseline
spec:
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - NET_BIND_SERVICE
          - CHOWN
EOF
then
    ink -r "ERROR: Should not be able to create privileged pod in namespace $NS"
    exit 1
else
    ink -y "EXPECTED ERROR: No able to create privileged pod in namespace $NS"
fi

# Let's apply the baseline Pod Security level and try again.
ink "Enforces a \"baseline\" security policy and warns / audits on restricted"
kubectl label --overwrite ns verify-pod-security \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

if cat <<EOF | kubectl -n verify-pod-security apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-baseline
spec:
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - NET_BIND_SERVICE
          - CHOWN
EOF
then
    ink "Create privileged pod in namespace $NS"
else
    ink -r "ERROR: No able to create privileged pod in namespace $NS"
    exit 1
fi

kubectl -n "$NS" delete pod ubuntu-baseline

# Restricted level and workload

ink "Enforces a \"restricted\" security policy and audits on restricted"
kubectl label --overwrite ns verify-pod-security \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted

if cat <<EOF | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-baseline
spec:
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - NET_BIND_SERVICE
          - CHOWN
EOF
then
    ink -r "ERROR: Should not be able to create privileged pod in namespace $NS"
    exit 1
else
    ink -y "EXPECTED ERROR: No able to create privileged pod in namespace $NS"
fi

if cat <<EOF | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-restricted
spec:
  securityContext:
    runAsUser: 65534
  containers:
  - name: ubuntu
    image: ubuntu:24.04
    args:
    - sleep
    - "1000000"
    securityContext:
      seccompProfile:
        type: RuntimeDefault
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
        add:
          - NET_BIND_SERVICE
EOF
then
    ink "Create pod in namespace $NS"
else
    ink -r "ERROR: No able to create pod in namespace $NS"
    exit 1
fi

# ink "Use 'docker exec -it <node-name> -- bash and crictl inspect' to check pods on nodes"
# node=$(kubectl get pod -n verify-pod-security ubuntu-restricted -o "jsonpath={.spec.nodeName}")
# docker exec -it $node crictl inspect ubuntu



