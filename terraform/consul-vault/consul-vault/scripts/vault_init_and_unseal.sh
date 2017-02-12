#!/bin/bash
set -e

sleep 5m

export VAULT_ADDR=http://127.0.0.1:8200

cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

if [ ! $(cget root-token) ]; then
  logger "$0 - Initializing Vault"
  vault init -address=http://localhost:8200 | tee /tmp/vault.init > /dev/null

  # Store master keys in consul for operator to retrieve and remove
  COUNTER=1
  grep 'Unseal' /tmp/vault.init | awk '{print $4}' | for key in $(cat -); do
    curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/unseal-key-$COUNTER -d $key
    COUNTER=$((COUNTER + 1))
  done

  export ROOT_TOKEN=$(grep 'Root' /tmp/vault.init | awk '{print $4}')
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/root-token -d $ROOT_TOKEN

  echo "Remove master keys from disk"
  #shred /tmp/vault.init

  #echo "Setup Vault demo"
  #curl -fX PUT 127.0.0.1:8500/v1/kv/service/nodejs/show_vault -d "true"
  #curl -fX PUT 127.0.0.1:8500/v1/kv/service/nodejs/vault_files -d "aws.html,generic.html"
else
  logger "$0 - Vault already initialized"
fi

logger "$0 - Unsealing Vault"
vault unseal $(cget unseal-key-1)
vault unseal $(cget unseal-key-2)
vault unseal $(cget unseal-key-3)

logger "$0 - Vault setup complete"


if vault status | grep active > /dev/null; then
  logger "$0 - Configuring AppRole"

  # auth with root token
  cget root-token | vault auth -

  # enable approle backend
  vault auth-enable approle

  # write some example secrets
  vault write secret/waycoolapp HomerSimpsonSSN="200-23-9930" MrBurnsSSN="000-00-0002"

  # create policy named 'waycoolapp'
  echo '
  path "secret/waycoolapp*" {
    capabilities = ["read"]
  }
  path "auth/token/renew" {
    capabilities = ["update"]
  }' | vault policy-write waycoolapp -

  # create approle for 'waycoolapp' with above policy and approle specific parameters
  vault write auth/approle/role/testrole secret_id_num_uses=1000 period=3600 policies=waycoolapp

  # read role_id for our approle
  vault read auth/approle/role/waycoolapp/role-id | grep role_id | awk '{print $2}' > /tmp/role_id

  # retreive secret_id for our approle, and subsequently upload to consul for retrieval
  # DEMO PURPOSES ONLY - NOT RECOMMENDED
  vault write -format=json -f auth/approle/role/waycoolapp/secret-id | tee \
  >(jq --raw-output '.data.secret_id' > /tmp/secret_id) \
  >(jq --raw-output '.data.secret_id_accessor' > /tmp/secret_id_accessor)
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/role_id -d $(cat /tmp/role_id)
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id -d $(cat /tmp/secret_id)
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id_accessor -d $(cat /tmp/secret_id_accessor)
fi

instructions() {
  cat <<EOF
We use an instance of HashiCorp Vault for secrets management.

It has been automatically initialized and unsealed once. Future unsealing must
be done manually.

The unseal keys and root token have been temporarily stored in Consul K/V.

  /service/vault/root-token
  /service/vault/unseal-key-{1..5}

Please securely distribute and record these secrets and remove them from Consul.
EOF

  exit 1
}

instructions
