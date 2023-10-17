#!/bin/bash

# Display the ssh command to connect to the instance

set -euo pipefail

instance_id=$(scw instance server list | grep openshift | awk '{print $1}')
ip_address=$(scw instance server wait "$instance_id" | grep PublicIP.Address | awk '{print $2}')

echo "ssh root@$ip_address"
