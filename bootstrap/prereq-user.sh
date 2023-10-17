#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. "$DIR"/conf.sh

sudo dnf install -y golang

mkdir -p $HOME/src

echo "PATH=\$PATH:\$HOME/go/bin" >>~/.bashrc
echo "PATH=\$PATH:\$HOME/crc-linux-$VERSION-amd64" >>~/.bashrc

# Install kubectl and setup auto-completion
if [ ! -e "$HOME/src/k8s-toolbox" ]; then
    echo "k8s-toolbox not found, downloading..."
    git clone https://github.com/k8s-school/k8s-toolbox $HOME/src/k8s-toolbox
else
    echo "k8s-toolbox found, skipping download..."
    cd $HOME/src/k8s-toolbox && git pull
fi
cd $HOME/src/k8s-toolbox && go install
sudo $HOME/go/bin/k8s-toolbox install kubectl
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Setup kubectl aliases
curl -Lo $HOME/.kubectl_aliases https://raw.githubusercontent.com/ahmetb/kubectl-alias/master/.kubectl_aliases
echo '[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases' >>~/.bashrc