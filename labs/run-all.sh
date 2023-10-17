#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Run test on internals"
"$DIR"/1_internals/ci.sh
echo
echo "Run test on authorization"
"$DIR"/2_authorization/ci.sh
echo
echo "Run test on policies"
"$DIR"/3_policies/ci.sh
echo
echo "Run test on computational resources"
"$DIR"/4_computational_resources/ci.sh
