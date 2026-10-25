#!/bin/bash

# Operators Lab 1 - Operator Lifecycle Manager (OLM) with the Grafana Operator
# Validate the solutions of https://k8s-school.fr/labs/k8s/en/1_labs/openshift-olm/index.html
# Requires OpenShift and cluster-admin.
#
# The cluster can be shared by several trainees:
# - the operator is cluster-wide (CRDs, AllNamespaces mode): only the trainer installs it (-s) and removes it (-c)
# - each trainee works in its own namespace 'grafana-<id>'

set -euxo pipefail

ID="${ID:-$(whoami)}"
NS="grafana-$ID"
OPERATOR_NS="openshift-operators"
PACKAGE="grafana-operator"
CHANNEL="v5"
SETUP=false
CLEANUP=false

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h         this message
    -s         trainer mode, install the Grafana Operator with OLM (Manual approval) and exit
    -c         trainer mode, uninstall the Grafana Operator and its CRDs and exit

Run the OLM exercise
EOD
}

# get the options
while getopts hsc c ; do
    case $c in
	    h) usage ; exit 0 ;;
	    s) SETUP=true ;;
	    c) CLEANUP=true ;;
	    \?) usage ; exit 2 ;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

# Wait until "$@" prints $expected
wait_for() {
    local expected="$1"
    shift
    for i in $(seq 1 60); do
        if [ "$("$@" 2>/dev/null)" = "$expected" ]; then
            return 0
        fi
        sleep 5
    done
    ink -r "Timeout: expected '$expected', got '$("$@" 2>/dev/null)'"
    exit 1
}

csv_name() {
    oc get subscription "$PACKAGE" -n "$OPERATOR_NS" -o jsonpath='{.status.installedCSV}'
}

subscription_settled() {
    case "$(oc get subscription "$PACKAGE" -n "$OPERATOR_NS" -o jsonpath='{.status.state}')" in
        UpgradePending|AtLatestKnown) echo true ;;
    esac
}

if [ "$CLEANUP" = true ]; then
    csv=$(csv_name 2>/dev/null || true)
    oc delete subscription "$PACKAGE" -n "$OPERATOR_NS" --ignore-not-found
    if [ -n "$csv" ]; then
        oc delete csv "$csv" -n "$OPERATOR_NS" --ignore-not-found
    fi
    # OLM leaves the CRDs, and therefore the custom resources, behind
    oc get crd -o name | grep 'grafana.integreatly.org' | xargs -r oc delete
    exit 0
fi

if [ "$SETUP" = true ]; then
    ink "Install the Grafana Operator in AllNamespaces mode, with Manual approval"
    # openshift-operators already holds the 'global-operators' OperatorGroup (AllNamespaces)
    oc get operatorgroup -n "$OPERATOR_NS"
    oc get packagemanifest "$PACKAGE" -n openshift-marketplace \
      -o jsonpath='{range .status.channels[*]}{.name}{" "}{.currentCSV}{"\n"}{end}'
    cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $PACKAGE
  namespace: $OPERATOR_NS
spec:
  channel: $CHANNEL
  name: $PACKAGE
  source: community-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Manual
EOF
    # A second run finds the operator already installed (AtLatestKnown)
    wait_for "true" subscription_settled
    if [ "$(oc get subscription "$PACKAGE" -n "$OPERATOR_NS" -o jsonpath='{.status.state}')" = "UpgradePending" ]; then
        ip=$(oc get subscription "$PACKAGE" -n "$OPERATOR_NS" -o jsonpath='{.status.installPlanRef.name}')
        oc get installplan "$ip" -n "$OPERATOR_NS"
        oc patch installplan "$ip" -n "$OPERATOR_NS" --type merge -p '{"spec":{"approved":true}}'
    fi
    # installedCSV is only set once the InstallPlan has run
    wait_for "AtLatestKnown" oc get subscription "$PACKAGE" -n "$OPERATOR_NS" -o jsonpath='{.status.state}'
    wait_for "Succeeded" oc get csv "$(csv_name)" -n "$OPERATOR_NS" -o jsonpath='{.status.phase}'
    exit 0
fi

oc delete project "$NS" --ignore-not-found --wait=true
oc new-project "$NS"

ink "Exercise 1: explore the objects created by OLM"
oc get subscription,installplan,operatorgroup -n "$OPERATOR_NS"
CSV=$(csv_name)
oc get csv "$CSV" -n "$OPERATOR_NS"
oc get csv "$CSV" -n "$OPERATOR_NS" -o jsonpath='{range .spec.customresourcedefinitions.owned[*]}{.kind}{" "}{.name}{"\n"}{end}'
oc get crd | grep grafana.integreatly.org
oc get deployments -n "$OPERATOR_NS"
# In AllNamespaces mode, OLM copies the CSV in every namespace
wait_for "Copied" oc get csv "$CSV" -n "$NS" -o jsonpath='{.status.reason}'
# OLM creates admin/edit/view ClusterRoles for each CRD, aggregated into the standard roles
oc get clusterroles | grep grafanas.grafana.integreatly.org

ink "Exercise 2: create a Grafana instance"
cat << EOF | oc apply -n "$NS" -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana
  labels:
    dashboards: grafana
spec:
  config:
    log:
      mode: console
  route:
    spec: {}
EOF
wait_for "success" oc get grafana grafana -n "$NS" -o jsonpath='{.status.stageStatus}'
oc get grafana grafana -n "$NS"
oc get deployment,service,route,configmap,secret,serviceaccount -n "$NS"
oc wait -n "$NS" --for=condition=available deployment grafana-deployment --timeout=300s
oc get deployment grafana-deployment -n "$NS" -o jsonpath='{.metadata.ownerReferences[*].kind}{"/"}{.metadata.ownerReferences[*].name}{"\n"}'

ink "Exercise 3: the operator reconciles the desired state"
uid=$(oc get deployment grafana-deployment -n "$NS" -o jsonpath='{.metadata.uid}')
oc delete deployment grafana-deployment -n "$NS"
new_uid() {
    local u
    u=$(oc get deployment grafana-deployment -n "$NS" -o jsonpath='{.metadata.uid}' 2>/dev/null || true)
    [ -n "$u" ] && [ "$u" != "$uid" ] && echo true
}
wait_for "true" new_uid
oc wait -n "$NS" --for=condition=available deployment grafana-deployment --timeout=300s

ink "Exercise 4: add a datasource and a dashboard"
cat << EOF | oc apply -n "$NS" -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: testdata
spec:
  instanceSelector:
    matchLabels:
      dashboards: grafana
  datasource:
    name: TestData
    type: grafana-testdata-datasource
    access: proxy
    isDefault: true
---
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: hello
spec:
  instanceSelector:
    matchLabels:
      dashboards: grafana
  json: |
    {
      "title": "Hello $ID",
      "panels": [
        {
          "type": "timeseries",
          "title": "Random walk",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
          "targets": [{"refId": "A", "scenarioId": "random_walk"}]
        }
      ]
    }
EOF

USER_GF=$(oc get secret grafana-admin-credentials -n "$NS" -o jsonpath='{.data.GF_SECURITY_ADMIN_USER}' | base64 -d)
PASS_GF=$(oc get secret grafana-admin-credentials -n "$NS" -o jsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d)
HOST=$(oc get route grafana-route -n "$NS" -o jsonpath='{.spec.host}')
gf() {
    curl -sk -u "$USER_GF:$PASS_GF" "https://$HOST$1"
}
wait_for "ok" sh -c "curl -sk https://$HOST/api/health | jq -r .database"
wait_for "Hello $ID" sh -c "curl -sk -u '$USER_GF:$PASS_GF' 'https://$HOST/api/search?type=dash-db' | jq -r '.[].title'"
wait_for "TestData" sh -c "curl -sk -u '$USER_GF:$PASS_GF' 'https://$HOST/api/datasources' | jq -r '.[].name'"
gf /api/search?type=dash-db | jq .

ink "Cleanup"
oc delete project "$NS"
