#!/bin/bash

# ssh helper script

set -euo pipefail

instance_id=$(scw instance server list | grep openshift | awk '{print $1}')
ip_address=$(scw instance server wait "$instance_id" | grep PublicIP.Address | awk '{print $2}')

ink "Command to connect to the instance:"
echo "ssh root@$ip_address"

ink "Command to create a tunnel to the instance:"
echo "ssh root@$ip_address -L 4040:localhost:4040 -N"
