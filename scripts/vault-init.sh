#!/usr/bin/env bash

set -e

echo "Initializing Vault..."
vault init -key-shares=1 -key-threshold=1 -address=http://0.0.0.0:8200 | sudo tee /tmp/vault.init

ROOT_TOKEN=$(grep 'Root' /tmp/vault.init | awk '{print $4}')
UNSEAL_KEY=$(grep 'Unseal' /tmp/vault.init | awk '{print $4}')


echo "Unsealing Vault..."
vault unseal $UNSEAL_KEY

echo "Verify status..."
vault status
