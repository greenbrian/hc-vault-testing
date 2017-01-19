#!/usr/bin/env bash

set -e

echo "Getting Vault status..."
sudo systemctl status -n 0 vault.service
echo "#######################"
echo "Restarting Vault now..."
sudo systemctl restart vault.service

sudo rm -f /tmp/role_id /tmp/secret_id /tmp/vault.init /tmp/accessor /tmp/client_token /tmp/token_renewal_output

sleep 5

bash /vagrant/scripts/vault-init.sh
