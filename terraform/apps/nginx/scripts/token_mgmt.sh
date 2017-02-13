#!/usr/bin/env bash

set -e

vault_addr="http://active.vault.service.dc1.consul:8200"
role_id_path="/tmp/role_id"
secret_id_path="/tmp/secret_id"
client_token_path="/ramdisk/client_token"

eval_vars() {
role_id=$(if [ -f "$role_id_path" ] && [ -s "$role_id_path" ]; then cat "$role_id_path" ; fi)
secret_id=$(if [ -f "$secret_id_path" ] && [ -s "$secret_id_path" ]; then cat "$secret_id_path" ; fi)
client_token=$(if [ -f "$client_token_path" ] && [ -s "$client_token_path" ]; then cat "$client_token_path" ; fi)
}

token_exists() {
if [ ! -s "$client_token_path" ]; then
  echo "$0 - Token does not exist"
  return 1
else
  echo 0
fi
}


fetch_token() {
  curl -X POST \
     --silent \
     -d '{"role_id":"'"$role_id"'","secret_id":"'"$secret_id"'"}' \
     $vault_addr/v1/auth/approle/login | tee \
     >(jq --raw-output '.auth.client_token' > ${client_token_path}) \
     > /dev/null
}

wait_for_role_id_and_secret_id() {
while [ ! -s "$role_id_path" ] || [ ! -s "$secret_id_path" ]; do
  echo "$0 - Waiting for role_id and secret_id"
  sleep 5
done
}

main() {
eval_vars
if token_exists; then
  echo "$0 - Token exists"
  exit 0
else
  wait_for_role_id_and_secret_id
  fetch_token
  exit 0
fi
}

main
