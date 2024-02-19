#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

IP=$($DIR/../scw/get_ip.sh)

scp pull-secret root@"$IP":/tmp
scp ~/.azure/osServicePrincipal.json root@"$IP":/tmp

ssh root@"$IP" mv /tmp/pull-secret /home/openshift/openshift-advanced/infra/az
ssh root@"$IP" "mkdir -p /home/openshift/.azure && mv /tmp/osServicePrincipal.json /home/openshift/.azure"

ssh root@"$IP" chown -R openshift:openshift /home/openshift/openshift-advanced/infra/az/pull-secret
ssh root@"$IP" chown -R openshift:openshift /home/openshift/.azure