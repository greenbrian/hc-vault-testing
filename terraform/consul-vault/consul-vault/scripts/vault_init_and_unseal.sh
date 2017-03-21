#!/bin/bash
set -e

export VAULT_ADDR=http://127.0.0.1:8200

# PKI specific variables
RootCAName="vault-ca-root"
IntermCAName="vault-ca-intermediate"
certs_dir="/tmp/certs"
sudo mkdir -p ${certs_dir}

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


policy_setup() {
  logger "$0 - Configuring Vault Policies"
  # create policy named 'waycoolapp'
  echo "
  path \"${IntermCAName}/issue*\" {
    capabilities = [\"create\",\"update\"]

  path \"secret/waycoolapp*\" {
    capabilities = [\"read\"]
  }
  path \"auth/token/renew\" {
    capabilities = [\"update\"]
  }
  path \"auth/token/renew-self\" {
    capabilities = [\"update\"]
  }
  " | vault policy-write waycoolapp -

  # create policy named 'admin-waycoolapp'
  echo '
  path "sys/mounts" {
    capabilities = ["list","read"]
  }
  path "secret/*" {
    capabilities = ["list", "read"]
  }
  path "secret/waycoolapp*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  path "secret/bgreen" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  path "supersecret/*" {
    capabilities = ["list", "read"]
  }' | vault policy-write admin-waycoolapp -
}

admin_setup() {
  logger "$0 - Configuring UserPass backend"
  # setup userpass for a personal login
  vault auth-enable userpass
  # create my credentials
  vault write auth/userpass/users/bgreen password=test policies="admin-waycoolapp"
}

approle_setup() {
  logger "$0 - Configuring AppRole"

  # enable approle backend
  vault auth-enable approle
  # create approle for 'waycoolapp' with above policy and approle specific parameters
  vault write auth/approle/role/waycoolapp secret_id_num_uses=1000 period=3600 policies=waycoolapp
  # read role_id for our approle
  vault read auth/approle/role/waycoolapp/role-id | grep role_id | awk '{print $2}' > /tmp/role_id
  # retrieve secret_id for our approle, and subsequently upload to consul for retrieval
  # DEMO PURPOSES ONLY - NOT RECOMMENDED
  vault write -format=json -f auth/approle/role/waycoolapp/secret-id | tee \
  >(jq --raw-output '.data.secret_id' > /tmp/secret_id) \
  >(jq --raw-output '.data.secret_id_accessor' > /tmp/secret_id_accessor)
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/role_id -d $(cat /tmp/role_id)
  sleep 2
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id -d $(cat /tmp/secret_id)
  sleep 2
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id_accessor -d $(cat /tmp/secret_id_accessor)
}

pki_setup() {


  # Mount Root CA and generate cert
  vault unmount ${RootCAName} $> /dev/null || true
  vault mount -path ${RootCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${RootCAName}
  vault write -format=json ${RootCAName}/root/generate/internal \
    common_name="${RootCAName}" ttl=87600h | tee \
    >(jq -r .data.certificate > $certs_dir/ca.pem) \
    >(jq -r .data.issuing_ca > $certs_dir/issuing_ca.pem) \
    >(jq -r .data.private_key > $certs_dir/ca-key.pem)

  # Mount Intermediate and set cert
  vault unmount ${IntermCAName} &> /dev/null || true
  vault mount -path ${IntermCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${IntermCAName}
  vault write -format=json ${IntermCAName}/intermediate/generate/internal \
    common_name="${IntermCAName}" ttl=43800h | tee \
    >(jq -r .data.csr > $certs_dir/${IntermCAName}.csr) \
    >(jq -r .data.private_key > $certs_dir/${IntermCAName}.pem)

  # Sign the intermediate certificate and set it
  vault write -format=json ${RootCAName}/root/sign-intermediate \
    csr=@$certs_dir/${IntermCAName}.csr \
    common_name="${IntermCAName}" ttl=43800h | tee \
    >(jq -r .data.certificate > $certs_dir/${IntermCAName}.pem) \
    >(jq -r .data.issuing_ca > $certs_dir/${IntermCAName}_issuing_ca.pem)
  vault write ${IntermCAName}/intermediate/set-signed certificate=@$certs_dir/${IntermCAName}.pem

  # Generate the roles
  vault write ${IntermCAName}/roles/example-dot-com allow_any_name=true max_ttl="1m"

  # concatenate CA certs for chain


}
if vault status | grep active > /dev/null; then
  # auth with root token
  cget root-token | vault auth -

  # setup audit log
  vault audit-enable file file_path=/var/log/vault_audit.log

  # write some example secrets
  vault write secret/waycoolapp User1SSN="200-23-9930" User2SSN="000-00-0002" ttl=60s

  policy_setup
  admin_setup
  approle_setup
  pki_setup
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
