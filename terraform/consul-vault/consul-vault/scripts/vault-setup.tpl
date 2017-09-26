#!/usr/bin/env bash
set -e

echo ${consul_server_count} > /tmp/consul-server-count
echo ${consul_server_addr} > /tmp/consul-server-addr

# Read from the files we created
SERVER_COUNT=$(cat /tmp/consul-server-count | tr -d '\n')
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-server \
-bootstrap-expect=${SERVER_COUNT} \
-join=${CONSUL_JOIN} \
-data-dir=/opt/consul/data \
-client 0.0.0.0 -ui"
EOF

# setup consul UI specific iptables rules
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8500 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables.rules

chown root:root /etc/default/consul
chmod 0644 /etc/default/consul

new_hostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
sudo hostname $new_hostname
sudo bash -c "cat >>/etc/hosts" << HOSTS
127.0.1.1 $new_hostname
HOSTS
sudo bash -c "cat >>/etc/hosts" << NEWHOSTNAME
$new_hostname
NEWHOSTNAME



systemctl enable consul.service
systemctl start consul
sleep 10

systemctl enable vault.service
systemctl start vault


#### vault initialization and unseal after waiting 3 minutes

sleep 180

export VAULT_ADDR=http://127.0.0.1:8200

# PKI specific variables
RootCAName="vault-ca-root"
IntermCAName="vault-ca-intermediate"
mkdir -p /tmp/certs/

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
sleep 25s


policy_setup() {
  logger "$0 - Configuring Vault Policies"
  # create policy named 'waycoolapp'
  echo "
  path \"${IntermCAName}/issue*\" {
    capabilities = [\"create\",\"update\"]
  }
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

  # create vault-admin policy
  echo '
  path "*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }' | vault policy-write vault-admin -

}

admin_setup() {
  logger "$0 - Configuring UserPass backend"
  # setup userpass for a personal login
  vault auth-enable userpass
  # create my credentials
  vault write auth/userpass/users/bgreen password=test policies="admin-waycoolapp"
  # create vault user admin credentials
  vault write auth/userpass/users/vault password=vault policies="vault-admin"
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
  vault unmount ${RootCAName} &> /dev/null || true
  vault mount -path ${RootCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${RootCAName}
  vault write -format=json ${RootCAName}/root/generate/internal \
  common_name="${RootCAName}" ttl=87600h | tee >(jq -r .data.certificate > /tmp/certs/ca.pem) >(jq -r .data.issuing_ca > /tmp/certs/issuing_ca.pem) >(jq -r .data.private_key > /tmp/certs/ca-key.pem)

  # Mount Intermediate and set cert
  vault unmount ${IntermCAName} &> /dev/null || true
  vault mount -path ${IntermCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${IntermCAName}
  vault write -format=json ${IntermCAName}/intermediate/generate/internal common_name="${IntermCAName}" ttl=43800h | tee >(jq -r .data.csr > /tmp/certs/${IntermCAName}.csr) >(jq -r .data.private_key > /tmp/certs/${IntermCAName}.pem)

  # Sign the intermediate certificate and set it
  vault write -format=json ${RootCAName}/root/sign-intermediate csr=@/tmp/certs/${IntermCAName}.csr common_name="${IntermCAName}" ttl=43800h | tee >(jq -r .data.certificate > /tmp/certs/${IntermCAName}.pem) >(jq -r .data.issuing_ca > /tmp/certs/${IntermCAName}_issuing_ca.pem)
  vault write ${IntermCAName}/intermediate/set-signed certificate=@/tmp/certs/${IntermCAName}.pem

  # Generate the roles
  vault write ${IntermCAName}/roles/example-dot-com allow_any_name=true max_ttl="1m"

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