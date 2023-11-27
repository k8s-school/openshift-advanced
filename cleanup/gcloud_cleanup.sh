#!/bin/bash

# Cleanup gcloud ssh keys

set -euxo pipefail

for i in $(gcloud compute os-login ssh-keys list --format="table[no-heading](value.fingerprint)"); do
  echo $i;
  gcloud compute os-login ssh-keys remove --key $i || true;
done
