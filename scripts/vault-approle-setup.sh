#!/usr/bin/env bash

set -e

VAULT_TOKEN=$(grep 'Root' /tmp/vault.init | awk '{print $4}')

echo "Enabling Vault AppRole backend..."
curl -X POST \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     -d '{"type":"approle"}' \
     http://127.0.0.1:8200/v1/sys/auth/approle

echo "Writing our application secrets..."
curl -X POST \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     -H "Content-Type: application/json" \
     http://127.0.0.1:8200/v1/secret/waycoolapp \
     -d '{"name":"Burns, Charles Montgomery", "ssn": "000-00-0002"}'

echo "Creating policy for AppRole..."
curl -X POST \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     http://127.0.0.1:8200/v1/sys/policy/waycoolapp \
     	-d '{"rules":"path \"secret/waycoolapp\" {\n  capabilities = [\"read\"]\n}"}'

echo "Creating AppRole..."
curl -X POST \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     -d '{"policies":"waycoolapp","secret_id_num_uses":"1000","secret_id_ttl":"60","token_ttl":"5m","token_max_ttl":"10m"}' \
     http://127.0.0.1:8200/v1/auth/approle/role/waycoolapp


echo "AppRole configuration complete!"
echo "###############################"

echo "Listing application secrets..."
curl -X GET \
     --silent \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     -H "Content-Type: application/json" \
     http://127.0.0.1:8200/v1/secret/waycoolapp | jq

echo "Listing policies for waycoolapp..."
curl -X GET \
     --silent \
     -H "X-Vault-Token:$VAULT_TOKEN" \
     -H "Content-Type: application/json" \
     http://127.0.0.1:8200/v1/sys/policy/waycoolapp | jq

# read out using CLI

# vault auth $(grep 'Root' /tmp/vault.init | awk '{print $4}')
# Successfully authenticated! You are now logged in.
# token: 4ca2f079-c822-5cf1-31df-e0d687d66791
# token_duration: 0
# token_policies: [root]

# vault policies waycoolapp
# path "secret/waycoolapp" {
#  capabilities = ["read"]
# }
