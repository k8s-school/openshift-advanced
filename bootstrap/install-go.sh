#!/bin/bash

set -euxo pipefail

GO_VERSION="1.21.5"

# Install Go
sudo rm -rf /usr/local/go
curl -sSL "https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz" | sudo tar -C /usr/local -xz

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
