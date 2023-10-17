#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/conf.sh

gcloud dns managed-zones create "$NAME" --description=openshift --dns-name="$ZONE" --labels=app=openshift --visibility=public
gcloud dns managed-zones describe "$NAME"

# See https://www.ovh.com/manager/#/web/domain/k8s-school.fr/dns