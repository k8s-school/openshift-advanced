#!/bin/bash

set -euxo pipefail

PROJECT=$(kubectl get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[0].metadata.labels.machine\.openshift\.io\/cluster-api-cluster}")

sed -i "s/demo-z2jlq/$PROJECT/g" machineset.yaml

PROJECT_=$(echo "${PROJECT/-/_}")

sed -i "s/demo_z2jlq/$PROJECT_/g" machineset.yaml

