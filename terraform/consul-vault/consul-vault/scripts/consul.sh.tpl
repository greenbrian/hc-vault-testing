#!/usr/bin/env bash
set -e

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-server \
-bootstrap-expect={{ consul_server_count }} \
-join={{ consul_join_address }} \
-data-dir=/opt/consul/data \
-client 0.0.0.0 -ui"
EOF

# setup consul UI specific iptables rules
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8500 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables.rules

sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul
