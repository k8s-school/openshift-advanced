#!/bin/bash

set -euo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

$DIR/1_RBAC_sa.sh
$DIR/2_RBAC_role.sh
$DIR/3_RBAC_clusterrole.sh                                                                             
