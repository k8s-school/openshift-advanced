#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

# TODO 2024 remove kubia and set fixed tag for alpine
# in order to avoid image pull
$DIR/ex1-securitycontext.sh
export EX3_SCC_FULL=true
$DIR/ex3-scc.sh
export EX4_NETWORK_FULL=true
$DIR/ex4-network.sh

# TODO 2024
ink -y "Run ex2-podsecurity.sh on k8s"

