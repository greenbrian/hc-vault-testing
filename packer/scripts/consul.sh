#!/usr/bin/env bash

set -e

cd /tmp


echo "Installing Consul..."
unzip -q consul.zip >/dev/null
chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /opt/consul/data
sudo mkdir -p /etc/consul.d/


echo "Configuring Consul firewall rules..."
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8300 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8301 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8302 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8400 -j ACCEPT
sudo netfilter-persistent save
sudo netfilter-persistent reload

echo "Installing Consul startup script..."
sudo bash -c "cat >/etc/systemd/system/consul.service" << 'EOF'
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/consul.service
