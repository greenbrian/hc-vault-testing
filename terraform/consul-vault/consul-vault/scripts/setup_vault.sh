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
