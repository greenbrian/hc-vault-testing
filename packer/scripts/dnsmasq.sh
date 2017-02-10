#!/usr/bin/env bash

echo "Installing dnsmqasq..."
sudo apt-get install -y -q dnsmasq

echo "Configuring DNSmasq"
sudo bash -c "cat >/etc/dnsmasq.d/10-consul" << EOF
server=/consul/127.0.0.1#8600
EOF
