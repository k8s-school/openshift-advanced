#!/bin/sh

DIR=$(cd "$(dirname "$0")"; pwd -P)


GREEN='\033[0;32m'
NC='\033[0m'
set -eux

NS="scc-example"
SA="fake-user"

# See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#run-another-pod
kubectl delete namespace -l "scc=true"
oc adm policy remove-scc-from-user anyuid -z $SA || echo
oc adm policy remove-scc-from-user anyuid -z $SA || echo
oc adm policy remove-scc-from-user hostpath-provisioner -z default || echo


oc new-project "$NS"
kubectl label ns "$NS" "scc=true"
kubectl create serviceaccount -n "$NS" $SA

# Allow fake-user to create pods and deployments
kubectl create rolebinding -n "$NS" edit --clusterrole=edit --serviceaccount="$NS":$SA

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


echo -e "$GREEN  Try to create pod ubuntu-simple $NC"
kubectl-user create -f /tmp/ubuntu-simple.yaml

echo -e "$GREEN Check access to scc $NC"
kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/restricted-v2

kubectl get pod ubuntu-simple -o yaml | grep -i runasuser
kubectl get pod ubuntu-simple -o yaml | grep -i scc

echo -e "$GREEN  Try to create pod ubuntu-root $NC"
if kubectl-user create -f /tmp/ubuntu-root.yaml
then
    >&2 echo "ERROR: User '$SA' should not be able to create pod ubuntu"
else
    >&2 echo "EXPECTED ERROR: User '$SA' cannot create pod"
fi

echo -e "$GREEN Get scc for pod ubuntu-root $NC"
oc adm policy scc-subject-review -f /tmp/ubuntu-root.yaml

echo -e "$GREEN Check access to scc $NC"
kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/anyuid ||
    >&2 echo "EXPECTED ERROR"

# kubectl-admin create role scc:anyuid \
#    --verb=use \
#    --resource=scc \
#    --resource-name=anyuid

echo -e "$GREEN Grant access to scc anyuid to service account $SA"
# WARN: it edits a clusterrolebinding
oc adm policy add-scc-to-user anyuid -z $SA

echo -e "$GREEN Check if service account can create pod ubuntu-root $NC"
oc adm policy scc-review -z system:serviceaccount:"$NS":$SA -f /tmp/ubuntu-root.yaml

echo -e "$GREEN Create pod ubuntu-root $NC"
kubectl-user create -f /tmp/ubuntu-root.yaml

kubectl-user create -f /tmp/ubuntu-privileged ||
    >&2 echo "EXPECTED ERROR: User '$SA' cannot create privileged container"

echo -e "$GREEN Show which SCCs is required by the pod ubuntu-privileged $NC"
oc adm policy scc-subject-review  -f /tmp/ubuntu-privileged.yaml

echo -e "$GREEN Grant access to scc hostpath-provisioner to service account $SA"
oc adm policy add-scc-to-user hostpath-provisioner -z $SA

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

kubectl-user apply -f /tmp/nginx-privileged.yaml
kubectl-user get pods
kubectl-user get events | head -n 2
oc adm policy add-scc-to-user hostpath-provisioner -z default


# Wait for deployment to recreate the pod
sleep 5
kubectl wait --timeout=60s --for=condition=Ready pods -l app=nginx -n "$NS"
kubectl-user get pods


