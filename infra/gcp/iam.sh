#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/conf.sh

gcloud config set project "$PROJECT_ID"

# https://docs.okd.io/latest/installing/installing_gcp/installing-gcp-account.html#installation-gcp-enabling-api-services_installing-gcp-account
# Required services
gcloud services enable compute.googleapis.com cloudresourcemanager.googleapis.com dns.googleapis.com iamcredentials.googleapis.com \
    iam.googleapis.com serviceusage.googleapis.com
