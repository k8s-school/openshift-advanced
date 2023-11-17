#!/bin/bash

# Launch remotely using the following command:
# curl -s https://raw.githubusercontent.com/k8s-school/openshift-advanced/main/init.sh | bash

set -euxo pipefail

dnf install -y bash-completion bind-utils git

user="openshift"
pass="0p&nsh!ft"

adduser "$user"
su - "$user" -c "git clone https://github.com/k8s-school/openshift-advanced.git"
echo "$user:$pass" | chpasswd

# Add sudo access without password
echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$user"

echo "Setup sshd"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl restart sshd

# Disable SELinux
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
setenforce Permissive


