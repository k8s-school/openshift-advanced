#!/bin/bash

set -euxo pipefail
shopt -s expand_aliases

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/../conf.version.sh

tmp_dir="$HOME/tmp"
mkdir -p $tmp_dir

EX3_SCC_FULL="${EX3_SCC_FULL:-false}"

ID="$(whoami)"
NS="scc-$ID"
SA="fake-user"

# See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#run-another-pod
kubectl delete namespace -l "scc=$ID"
oc adm policy remove-scc-from-user anyuid -z $SA || ink -y "WARN: anyuid not allowed to $SA"
oc adm policy remove-scc-from-user hostpath-provisioner -z $SA || ink -y "WARN: hostpath-provisioner not allowed to $SA"
oc adm policy remove-scc-from-user hostpath-provisioner -z default || ink -y "WARN: hostpath-provisioner not allowed to default"

oc new-project "$NS"
kubectl label ns "$NS" "scc=$ID"
kubectl create serviceaccount -n "$NS" $SA

# WARN alias does not work with bash
shopt -s expand_aliases
alias kubectl-admin='kubectl -n "$NS"'
alias kubectl-user='kubectl --as=system:serviceaccount:$NS:$SA -n "$NS"'


if [ "$EX3_SCC_FULL" = false ]
then
    exit 0
fi

ink "Allow fake-user to create pods and deployments only in $NS"
kubectl create rolebinding -n "$NS" edit --clusterrole=edit --serviceaccount="$NS":$SA

ink "Try to create pod ubuntu-simple"
kubectl-user create -f $tmp_dir/ubuntu-simple.yaml

ink "Check access to scc"
kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/restricted-v2

ink "Check which scc was used"
kubectl get pod ubuntu-simple -o yaml | grep -i runasuser
kubectl get pod ubuntu-simple -o yaml | grep -i scc

ink "Show which SCC is required by the pod ubuntu-simple"
ink "WARN: command should not display anyuid here: inconsistency"
oc adm policy scc-subject-review -f $tmp_dir/ubuntu-simple.yaml

ink "Try to create pod ubuntu-root"
if kubectl-user create -f $tmp_dir/ubuntu-root.yaml
then
    ink -r "ERROR: User '$SA' should not be able to create pod ubuntu root"
    exit 1
else
    ink -y "EXPECTED ERROR: User '$SA' cannot create pod"
fi

ink "Get scc for pod ubuntu-root"
oc adm policy scc-subject-review -f $tmp_dir/ubuntu-root.yaml

ink "Check access to scc"
if kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/anyuid
then
    ink -r "ERROR: User '$SA' should not be able to use scc/anyuid"
    exit 1
else
    ink -y "EXPECTED ERROR: User '$SA' cannot use scc/anyuid"
fi

# kubectl-admin create role scc:anyuid \
#    --verb=use \
#    --resource=scc \
#    --resource-name=anyuid

ink "Grant access to scc anyuid to service account $SA"
# WARN: it edits a clusterrolebinding
oc adm policy add-scc-to-user anyuid -z $SA

ink "Check if service account can create pod ubuntu-root"
oc adm policy scc-review -z system:serviceaccount:"$NS":$SA -f $tmp_dir/ubuntu-root.yaml

ink "Create pod ubuntu-root"
kubectl-user create -f $tmp_dir/ubuntu-root.yaml

if kubectl-user create -f $tmp_dir/ubuntu-privileged
then
    ink -r "ERROR: User '$SA' should not be able to create privileged pod"
    exit 1
else
    ink -y "EXPECTED ERROR: User '$SA' cannot create privileged pod"
fi

ink "Show which SCC is required by the pod ubuntu-privileged"
oc adm policy scc-subject-review  -f $tmp_dir/ubuntu-privileged.yaml

ink "Grant access to scc hostpath-provisioner to service account $SA"
oc adm policy add-scc-to-user hostpath-provisioner -z $SA

ink "Create pod ubuntu-privileged"
kubectl-user create -f $tmp_dir/ubuntu-privileged.yaml


ink "Create nginx deployment"
kubectl-user apply -f $tmp_dir/nginx-privileged.yaml
kubectl-user get pods
kubectl-user get events

ink "Grant access to scc hostpath-provisioner to service account default"
oc adm policy add-scc-to-user hostpath-provisioner -z default

# Wait for deployment to recreate the pod
sleep 5
kubectl wait --timeout=60s --for=condition=Ready pods -l app=nginx -n "$NS"
kubectl-user get pods

