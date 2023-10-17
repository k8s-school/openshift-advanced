#!/bin/sh

DIR=$(cd "$(dirname "$0")"; pwd -P)

set -eux

NS="scc-example"

# See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#run-another-pod
kubectl delete namespace -l "scc=true"

oc new-project "$NS"
kubectl label ns "$NS" "scc=true"
kubectl create serviceaccount -n "$NS" fake-user

# Allow fake-user to create pods
kubectl create rolebinding -n "$NS" fake-editor --clusterrole=edit --serviceaccount="$NS":fake-user

alias kubectl-admin='kubectl -n "$NS"'
alias kubectl-user='kubectl --as=system:serviceaccount:"$NS":fake-user -n "$NS"'

cat <<EOF > /tmp/ubuntu-root.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-root
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        runAsUser: 0
EOF

 oc adm policy scc-subject-review -f /tmp/ubuntu-root.yaml

if kubectl-user create -f /tmp/ubuntu-root.yaml
then
    >&2 echo "ERROR: User 'fake-user' should not be able to create pod ubuntu"
else
    >&2 echo "EXPECTED ERROR: User 'fake-user' cannot create pod"
fi


cat <<EOF > /tmp/ubuntu-runasuser.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-1000750001
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        runAsUser: 1000750001
EOF

cat <<EOF > /tmp/ubuntu-free.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-free
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
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        privileged: true
EOF


kubectl --as=system:serviceaccount:"$NS":fake-user  auth can-i use scc/restricted-v2
kubectl --as=system:serviceaccount:"$NS":fake-user  auth can-i use scc/anyuid ||
    >&2 echo "EXPECTED ERROR"

# kubectl-admin create role psp:unprivileged \
#    --verb=use \
#    --resource=scc \
#    --resource-name=example

# WARN: it edits a clusterrolebinding
oc adm policy add-scc-to-user anyuid -z fake-user
oc adm policy scc-review -z system:serviceaccount:"$NS":fake-user -f /tmp/ubuntu-root.yaml

# Show which SCCs is required by the pod
oc adm policy scc-subject-review  -f /tmp/ubuntu-privileged.yaml

kubectl apply -n "$NS" -f "$DIR"/resource/role-use-scc.yaml

kubectl-admin create rolebinding fake-user:scc:anyuid \
    --role=scc:anyuid \
    --serviceaccount="$NS":fake-user

kubectl-user create -f /tmp/ubuntu-privileged ||
    >&2 echo "EXPECTED ERROR: User 'fake-user' cannot create privileged container"

kubectl-user delete pod pause

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
kubectl-admin create rolebinding default:scc:hostpath-provisioner \
    --role=psp:unprivileged \
    --serviceaccount="$NS":default
# Wait for deployment to recreate the pod
sleep 5
kubectl wait --timeout=60s --for=condition=Ready pods -l app=nginx -n "$NS"
kubectl-user get pods

oc adm policy remove-scc-from-user hostpath-provisioner -z default
