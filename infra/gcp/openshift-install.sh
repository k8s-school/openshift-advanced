#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/conf.sh

archive="/tmp/openshift.tar.gz"


if [ ! -e $DIR/openshift-install ]; then
    echo "Download openshift-install"
    curl -L https://github.com/okd-project/okd/releases/download/4.13.0-0.okd-2023-09-03-082426/openshift-install-linux-4.13.0-0.okd-2023-09-03-082426.tar.gz \
    -o "$archive"
    tar -xzf "$archive" -C "$DIR"
fi

$DIR/openshift-install create install-config --dir "$INSTALL_DIR"
$DIR/openshift-install create cluster --dir="$INSTALL_DIR" --log-level=debug