#!/bin/bash

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

# Openshift exercices
$DIR/ex1.sh
$DIR/ex2-backup.sh
