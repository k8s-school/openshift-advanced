#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

IP=$($DIR/../scw/get_ip.sh)

# TODO move to right directory
scp pull-secret root@"$IP":/tmp
scp ~/.azure/osServicePrincipal.json root@"$IP":/tmp

# TODO
ssh root@"$IP" sh -c "chown openshift:openshift /tmp/pull-secret && sudo su openshift && mv /tmp/pull-secret /home/openshift/openshift-advanced/"
ssh root@"$IP" sh -c "chown openshift:openshift /tmp/osServicePrincipal.json && sudo su openshift && mkdir -p /home/openshift/.azure && mv /tmp/osServicePrincipal.json /home/openshift/.azure"
