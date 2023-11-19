#!/bin/bash

# Terminate the 'openshift' instance on Scaleway


set -euxo pipefail

instance_id=$(scw instance server list | grep openshift | awk '{print $1}')

if [ -n "$instance_id" ]; then
  echo "Terminate $instance_id"
  scw instance server terminate "$instance_id"
else
  echo "Instance openshift not created"
  exit 1
fi
