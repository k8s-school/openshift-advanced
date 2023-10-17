#!/bin/bash

set -euxo pipefail

# See https://www.itsfullofstars.de/2021/07/remote-access-to-red-hat-crc/
# or https://cloud.redhat.com/blog/accessing-codeready-containers-on-a-remote-server/


# Configuring the Host Machine

sudo dnf -y install haproxy policycoreutils-python-utils


# Configuring the Firewall
# sudo dnf -y install firewalld
# sudo systemctl unmask firewalld
# sudo systemctl enable firewalld
# sudo systemctl start firewalld
# sudo firewall-cmd --add-port=80/tcp --permanent
# sudo firewall-cmd --add-port=6443/tcp --permanent
# sudo firewall-cmd --add-port=443/tcp --permanent
# sudo systemctl restart firewalld
# sudo semanage port -a -t http_port_t -p tcp 6443 || echo "WARN: Port may already be configured"

# Warn disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Configuring HA Proxy

# Scaleway specific
export SERVER_IP=$(ip add show eth0 | grep -w inet | awk '{print $2;exit}' | cut -d'/' -f1)
export CRC_IP=$(crc ip)

HA_PROXY_CONFIG=/etc/haproxy/haproxy.cfg
sudo cp "$HA_PROXY_CONFIG" /etc/haproxy/haproxy.cfg.orig

sudo bash -c "cat > $HA_PROXY_CONFIG" << EOF
global
    log /dev/log local0
defaults
    balance roundrobin
    log global
    maxconn 100
    mode tcp
    timeout connect 5s
    timeout client 500s
    timeout server 500s
listen apps
    bind 0.0.0.0:80
    server crcvm CRC_IP:80 check
listen apps_ssl
    bind 0.0.0.0:443
    server crcvm CRC_IP:443 check
listen api
    bind 0.0.0.0:6443
    server crcvm CRC_IP:6443 check
EOF

sudo sed -i "s/SERVER_IP/$SERVER_IP/g" "$HA_PROXY_CONFIG"
sudo sed -i "s/CRC_IP/$CRC_IP/g" "$HA_PROXY_CONFIG"

sudo systemctl start haproxy
