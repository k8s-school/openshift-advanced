#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. $DIR/conf.sh

# Create service account
gcloud iam service-accounts create "$SA_NAME" \
  --description="$DESCRIPTION" \
  --display-name="$DISPLAY_NAME"

# Add owner role to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_ID" \
  --role="roles/owner"

# List roles for service account
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format='table(bindings.role)' \
  --filter="bindings.members:serviceAccount:$SA_ID"

# Create service account key
gcloud iam service-accounts keys create $INSTALL_DIR/$SA_NAME-private-key.json \
  --iam-account="$SA_KEY"