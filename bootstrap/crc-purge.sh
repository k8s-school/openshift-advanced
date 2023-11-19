#!/bin/bash

set -euxo pipefail

crc="$HOME/crc-linux-$VERSION-amd64"/crc
$crc delete
rm -rf "$HOME/.crc/cache/*"
