#!/usr/bin/env bash

set -e

echo "Getting Vault status..."
sudo service vault status
echo "#######################"
echo "Restarting Vault now..."
sudo service vault restart

sleep 5

bash /vagrant/scripts/vault-init.sh
