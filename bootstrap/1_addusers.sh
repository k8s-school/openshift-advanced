#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/env.sh

for ((i=1; i<=$NB_USER; i++))
do
  USER="k8s${i}"
  echo $USER
  id -u $USER &>/dev/null || sudo useradd "$USER" --create-home --groups docker --shell /bin/bash
  echo "${USER}:${i}${PASS}" | sudo chpasswd
done

