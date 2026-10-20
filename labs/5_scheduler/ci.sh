#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

# Two trainees in parallel on the same cluster
ID=trainee1 $DIR/ex1-placement.sh &
pid1=$!
ID=trainee2 $DIR/ex1-placement.sh &
pid2=$!
wait $pid1
wait $pid2
$DIR/ex1-placement.sh -s
$DIR/ex1-placement.sh -c
