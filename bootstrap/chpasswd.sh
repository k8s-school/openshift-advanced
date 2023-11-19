#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/env.sh

for ((i=0; i<=$NB_USER; i++))
do
  USER="k8s${i}"
  echo "${USER}:${i}${PASS}" | sudo chpasswd
done

