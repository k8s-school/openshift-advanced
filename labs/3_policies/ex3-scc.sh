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

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h         this message
    -s         run exercice and solution

Run scc exercice
EOD
}

# get the options
while getopts hs c ; do
    case $c in
	    h) usage ; exit 0 ;;
	    s) EX3_SCC_FULL=true ;;
	    \?) usage ; exit 2 ;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

# WARN alias does not work with bash
shopt -s expand_aliases
alias kubectl-admin='kubectl -n "$NS"'
alias kubectl-user='kubectl --as=system:serviceaccount:$NS:$SA -n "$NS"'

# See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#run-another-pod
ink "Reset scc namespace $NS and remove related scc"
kubectl config set-context --current --namespace=$NS
for policy in anyuid hostpath-provisioner
do
    for sa in $SA default
    do
        if kubectl --as=system:serviceaccount:"$NS":$sa  auth can-i use scc/$policy; then
            ink -y "Remove scc/$policy for serviceaccount $sa in namespace $NS"
            oc adm policy remove-scc-from-user $policy -z $sa
        else
            ink -y "Serviceaccount '$sa' cannot use scc/$policy"
        fi
    done
done
kubectl delete namespace -l "scc=$ID"

ink "Create namespace $NS and service account $SA"
oc new-project "$NS"
kubectl label ns "$NS" "scc=$ID"
kubectl create serviceaccount -n "$NS" $SA

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
if kubectl --as=system:serviceaccount:"$NS":$SA  auth can-i use scc/anyuid; then
    ink -r "ERROR: User '$SA' should not be able to use scc/anyuid"
    exit 1
else
    ink -y "EXPECTED ERROR: User '$SA' cannot use scc/anyuid"
fi

ink "Check which scc was used"
kubectl get pod ubuntu-simple -o yaml | grep -i scc

ink "Show which SCC is required by the pod ubuntu-simple"
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

ink "Create pod ubuntu-root with success"
kubectl-user create -f $tmp_dir/ubuntu-root.yaml

ink "Try to create pod ubuntu-privileged"
if kubectl-user create -f $tmp_dir/ubuntu-privileged.yaml
then
    ink -r "ERROR: User '$SA' should not be able to create privileged pod"
    exit 1
else
    ink -y "EXPECTED ERROR: User '$SA' cannot create privileged pod"
fi

ink "Show which SCC is required by the pod ubuntu-privileged"
ink -y "Commands below are not so well documented"
oc adm policy scc-subject-review  -f $tmp_dir/ubuntu-privileged.yaml
oc adm policy scc-subject-review -z system:serviceaccount:scc-openshift:fake-user -f ~/tmp/ubuntu-privileged.yaml
oc adm policy scc-review -z system:serviceaccount:scc-openshift:fake-user -f ~/tmp/ubuntu-privileged.yaml

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

ink "Wait for deployment to recreate the pod"
sleep 5
kubectl wait --timeout=60s --for=condition=Ready pods -l app=nginx -n "$NS"
kubectl-user get pods

