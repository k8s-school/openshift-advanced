#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/conf.sh

$DIR/openshift-install destroy cluster --dir "$INSTALL_DIR"
$DIR/openshift-install destroy bootstrap --dir "$INSTALL_DIR"

