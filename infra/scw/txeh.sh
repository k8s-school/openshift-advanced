#!/bin/bash

# Create a new instance on Scaleway

# Launch remotely using the following command:
# curl -s https://raw.githubusercontent.com/k8s-school/openshift-advanced/main/0_setup.sh | bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

OPENSHIFT_USER="openshift"
INSTANCE_NAME="openshiftlarge"
INSTANCE_TYPE="GP1-M"

instance_id=$(scw instance server list | grep "$INSTANCE_NAME" | awk '{print $1}')
ip_address=$(scw instance server wait "$instance_id" | grep PublicIP.Address | awk '{print $2}')

sudo $(which txeh) add "$ip_address" api.crc.testing console-openshift-console.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing oauth-openshift.apps-crc.testing

