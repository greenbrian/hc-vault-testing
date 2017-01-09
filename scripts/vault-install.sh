#!/usr/bin/env bash

set -e

echo "Installing a few base packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install --yes curl wget unzip iptables-persistent jq

echo "Fetching Vault..."
VAULT=0.6.4
cd /tmp
wget https://releases.hashicorp.com/vault/${VAULT}/vault_${VAULT}_linux_amd64.zip \
    --quiet \
    -O vault.zip

echo "Installing Vault..."
unzip -q vault.zip >/dev/null
chmod +x vault
sudo mv vault /usr/local/bin
sudo chmod 0755 /usr/local/bin/vault
sudo chown root:root /usr/local/bin/vault
sudo mkdir -p /etc/systemd/system/vault.d
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

echo "Configuring Vault firewall rules..."
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8200 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8125 -j ACCEPT
sudo netfilter-persistent save
sudo netfilter-persistent reload


echo "Configuring Vault..."
sudo bash -c "cat >/etc/systemd/system/vault.d/config.json" << VAULTCONF
backend "inmem" {}
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}
VAULTCONF


echo "Configuring Vault environment..."
sudo bash -c "cat >/etc/profile.d/vault.sh" << VAULTENV
export VAULT_ADDR=http://127.0.0.1:8200
VAULTENV
sudo chmod 755 /etc/profile.d/vault.sh


echo "Installing Vault startup script..."
sudo bash -c "cat >/etc/systemd/system/vault.service" << 'VAULTSVC'
[Unit]
Description=vault agent
Requires=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/default/vault
Restart=on-failure
ExecStart=/usr/local/bin/vault server $VAULT_FLAGS -config=/etc/systemd/system/vault.d/config.json
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
VAULTSVC

sudo chmod 0644 /etc/systemd/system/vault.service

echo "Starting Vault..."
sudo service vault start
