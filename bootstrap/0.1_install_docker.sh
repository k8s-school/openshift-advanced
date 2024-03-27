#!/bin/bash

set -euxo pipefail

sudo dnf install -y docker
sudo usermod -a -G docker $USER
# newgrp docker
sudo systemctl start docker

# Increase the inotify watch limit
# see https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
echo fs.inotify.max_user_instances=512 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
# Monitor
sysctl fs.inotify.max_user_watches
sysctl fs.inotify.max_user_instances
