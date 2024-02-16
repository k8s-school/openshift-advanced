#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

ink "Running podsecurity and network policies exercises on k8s"
ink "in order to avoid interference with OpenShift security context constraints"

$DIR/ex2-podsecurity.sh
export EX4_NETWORK_FULL=true
$DIR/ex4-network.sh


