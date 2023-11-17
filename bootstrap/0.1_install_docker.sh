#!/bin/bash

set -euxo pipefail

sudo dnf install -y docker
sudo usermod -a -G docker $USER
# newgrp docker
sudo systemctl start docker

