#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

IP=$($DIR/../scw/get_ip.sh)

# TODO move to right directory
scp pull-secret root@"$IP":/tmp
scp ~/.azure/osServicePrincipal.json root@"$IP"
