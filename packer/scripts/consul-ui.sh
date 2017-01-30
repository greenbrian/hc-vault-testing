#!/usr/bin/env bash

set -e
sudo mkdir /opt/consul-ui

echo "Fetching Consul Web UI..."
VERSION=0.7.0
cd /tmp
wget https://releases.hashicorp.com/consul/${VERSION}/consul_${VERSION}_web_ui.zip \
    --quiet \
    -O consul_ui.zip

echo "Installing Consul Web UI..."
sudo unzip consul_ui.zip -d /opt/consul-ui
