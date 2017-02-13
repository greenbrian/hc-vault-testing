#!/usr/bin/env bash

set -e

vault_addr="http://active.vault.service.dc1.consul:8200"
role_id_path="/tmp/role_id"
secret_id_path="/tmp/secret_id"
client_token_path="/ramdisk/client_token"

if [ -s "$client_token_path" ]; then
  echo "$0 - Token exists"
  exit 0
else
  while [ ! -s "$role_id_path" ] || [ ! -s "$secret_id_path" ]; do
    echo "$0 - Waiting for role_id and secret_id"
    sleep 5
  done
  curl -X POST \
  --silent \
  -d '{"role_id":"'"$(cat $role_id_path)"'","secret_id":"'"$(cat $secret_id_path)"'"}' \
  $vault_addr/v1/auth/approle/login | tee \
  >(jq --raw-output '.auth.client_token' > ${client_token_path}) \
  > /dev/null
  exit 0
fi
