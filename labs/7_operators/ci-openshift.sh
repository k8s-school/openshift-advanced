#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

# The trainer installs the operator, then two trainees work in parallel on the same cluster
$DIR/ex1-olm-grafana.sh -s
ID=trainee1 $DIR/ex1-olm-grafana.sh &
pid1=$!
ID=trainee2 $DIR/ex1-olm-grafana.sh &
pid2=$!
wait $pid1
wait $pid2
$DIR/ex1-olm-grafana.sh -c
