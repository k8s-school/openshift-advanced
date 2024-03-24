#!/bin/bash

set -euxo pipefail

ink "Monitoring"
kubectl get -n openshift-machine-api machinesets.machine.openshift.io
kubectl get machine -A
echo
ink "Advanced monitoring"
kubectl get pod -n openshift-machine-api
kubectl get pod -n openshift-cloud-controller-manager
