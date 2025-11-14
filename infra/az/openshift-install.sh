#!/bin/bash

set -euxo pipefail

# OPENSHIFT_VERSION="4.16.15"
OPENSHIFT_VERSION="4.20.4"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/conf.sh

archive="/tmp/openshift.tar.gz"

sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

# URL="https://github.com/okd-project/okd/releases/download/4.13.0-0.okd-2023-09-30-084937/openshift-install-linux-4.13.0-0.okd-2023-09-30-084937.tar.gz"
URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_VERSION/openshift-install-linux-$OPENSHIFT_VERSION.tar.gz"
if [ ! -e $DIR/openshift-install ]; then
    echo "Download openshift-install"
    curl -L "$URL" -o "$archive"
    tar -xzf "$archive" -C "$DIR"
fi

# $DIR/openshift-install create install-config --dir "$INSTALL_DIR"
cp $DIR/install-config.yaml $INSTALL_DIR
# Edit $INSTALL_DIR/install-config.yaml and then run:
$DIR/openshift-install create cluster --dir="$INSTALL_DIR" --log-level=debug
