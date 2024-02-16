#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

$DIR/ex1-securitycontext.sh
export EX3_SCC_FULL=true
$DIR/ex3-prereq.sh
$DIR/ex3-scc.sh
