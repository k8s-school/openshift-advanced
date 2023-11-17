#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. "$DIR"/conf.sh

sudo dnf install -y golang byobu

mkdir -p $HOME/src

echo "PATH=\$PATH:\$HOME/go/bin" >>~/.bashrc
echo "PATH=\$PATH:\$HOME/crc-linux-$VERSION-amd64" >>~/.bashrc

# Install kubectl and setup auto-completion
go install github.com/k8s-school/ktbx@v1.1.1-rc6
sudo cp "$HOME/go/bin/ktbx" "/usr/local/bin"
go install -v github.com/k8s-school/ink@v0.0.1-rc3
sudo cp "$HOME/go/bin/ink" "/usr/local/bin"

ktbx install kind
ktbx install kubectl
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Setup kubectl aliases
curl -Lo $HOME/.kubectl_aliases https://raw.githubusercontent.com/ahmetb/kubectl-alias/master/.kubectl_aliases
echo '[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases' >>~/.bashrc

mkdir -p $HOME/.kube
mkdir -p $HOME/.ktbx/homefs

# SELinux setup
chcon -Rt svirt_sandbox_file_t $HOME/.kube
chcon -Rt svirt_sandbox_file_t $HOME/.ktbx/homefs
sudo chcon -Rt svirt_sandbox_file_t /etc/group
sudo chcon -Rt svirt_sandbox_file_t /etc/passwd
