#!/bin/bash

set -euxo pipefail

PROJECT=$(kubectl get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[1].metadata.labels.machine\.openshift\.io\/cluster-api-cluster}")

sed "s/<infrastructure_id>/$PROJECT/g" machineset.4.19.yaml > machineset.tmp.yaml

PROJECT_=$(echo "${PROJECT/-/_}")

sed "s/<machineset_name>/$PROJECT_/g" machineset.tmp.yaml > machineset.$PROJECT_.tmp.yaml

echo "Generated file: machineset.$PROJECT_.tmp.yaml"