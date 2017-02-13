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

echo "Installing Consul-template script..."
sudo bash -c "cat >/usr/local/bin/consul-template.sh" << 'EOF'
#!/usr/bin/env bash
/usr/local/bin/consul-template \
-config=/etc/systemd/system/consul-template.d/consul-template.json \
-vault-token=$(cat /ramdisk/client_token)
EOF

echo "Installing Systemd service..."
sudo mkdir -p /etc/systemd/system/consul-template.d/templates
sudo bash -c "cat >/etc/systemd/system/consul-template.service" << 'EOF'
[Unit]
Description=consul-template agent
Requires=network-online.target
After=network-online.target consul.service
OnFailure=token_mgmt.service

[Service]
Restart=on-failure
RestartSec=15
ExecStart=/usr/local/bin/consul-template.sh
ExecStart=/usr/local/bin/consul-template -config=/etc/systemd/system/consul-template.d/consul-template.json
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/consul-template.service
sudo chmod 0755 /usr/local/bin/consul-template.sh
