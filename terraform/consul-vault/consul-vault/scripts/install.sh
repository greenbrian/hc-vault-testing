#!/usr/bin/env bash
set -e

# Read from the file we created
SERVER_COUNT=$(cat /tmp/consul-server-count | tr -d '\n')
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-server \
-bootstrap-expect=${SERVER_COUNT} \
-join=${CONSUL_JOIN} \
-data-dir=/opt/consul/data \
-client 0.0.0.0 -ui"
EOF

# setup consul UI specific iptables rules
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8500 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables.rules

sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul

hostname consul_vault.$(curl http://169.254.169.254/latest/meta-data/instance-id)
echo "127.0.1.1 consul_vault.$(curl http://169.254.169.254/latest/meta-data/instance-id)" >> /etc/hosts
echo "consul_vault.$(curl http://169.254.169.254/latest/meta-data/instance-id)" > /etc/hostname
