#!/bin/bash

set -euxo pipefail

mkdir -p $HOME/src

sudo dnf install -y docker java-latest-openjdk
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker "$USER"

fink_repos="fink-broker fink-alert-simulator finkctl"
branch="729-run-ci-on-self-hosted-runner"
echo "Cloning Fink repositories $fink_repos from branch $branch"

for repo in $fink_repos; do
    repo_url="https://github.com/astrolabsoftware/$repo"
    if [ -e "$HOME/src/$repo" ]; then
        echo "$repo found, skipping download..."
    else
        echo "$repo not found, downloading..."
        git clone $repo_url $HOME/src/$repo
    fi
    cd $HOME/src/$repo
    git pull
    # Retrieve branch if it exists, else use main branch
    if git ls-remote --exit-code --heads "$repo_url" "$branch"
    then
        repo_branch="$branch"
    elif git ls-remote --exit-code --heads "$repo_url" "master"
    then
        # FIXME branch name should be main but may be master...
        repo_branch="master"
    else
        repo_branch="main"
    fi

    git checkout $repo_branch
done

cd $HOME/src/finkctl && go install

echo "Add Fink aliases"
echo 'source /home/openshift/src/fink-broker/examples/alias-fink.sh' >>~/.bashrc

export MINIMAL=true
export NOSCIENCE=true

echo "Install and run Fink stack"
$HOME/src/fink-alert-simulator/prereq-install.sh
$HOME/src/fink-broker/itest/prereq-install.sh
$HOME/src/fink-broker/itest/strimzi-install.sh
$HOME/src/fink-broker/itest/strimzi-setup.sh
$HOME/src/fink-broker/itest/minio-install.sh
$HOME/src/fink-alert-simulator/argo-submit.sh
$HOME/src/fink-broker/itest/fink-start.sh
$HOME/src/fink-broker/itest/check-results.sh

