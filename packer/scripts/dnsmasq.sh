#!/usr/bin/env bash

echo "Installing dnsmqasq..."
sudo apt-get install -y -q dnsmasq

echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul
