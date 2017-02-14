#!/usr/bin/env bash

set -e

echo "Fetching Consul Template..."
VERSION=0.18.0
cd /tmp
wget https://releases.hashicorp.com/consul-template/${VERSION}/consul-template_${VERSION}_linux_amd64.zip \
    --quiet \
    -O consul_template.zip

echo "Installing Consul Template..."
unzip -q consul_template.zip >/dev/null
chmod +x consul-template
sudo mv consul-template /usr/local/bin/consul-template

echo "Installing Systemd service..."
sudo mkdir -p /etc/systemd/system/consul-template.d/templates
sudo bash -c "cat >/etc/systemd/system/consul-template.service" << 'EOF'
[Unit]
Description=consul-template agent
Requires=network-online.target
After=network-online.target consul.service

[Service]
EnvironmentFile=/ramdisk/client_token
Restart=on-failure
ExecStart=/usr/local/bin/consul-template -config=/etc/systemd/system/consul-template.d/consul-template.json $client_token
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF


sudo chmod 0644 /etc/systemd/system/consul-template.service
