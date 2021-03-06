#!/usr/bin/env bash

set -e

vault_addr="http://127.0.0.1:8200"
role_id_path="/tmp/role_id"
secret_id_path="/tmp/secret_id"
client_token_path="/tmp/client_token"
accessor_path="/tmp/accessor"

eval_vars() {
role_id=$(if [ -f "$role_id_path" ] && [ -s "$role_id_path" ]; then cat "$role_id_path" ; fi)
secret_id=$(if [ -f "$secret_id_path" ] && [ -s "$secret_id_path" ]; then cat "$secret_id_path" ; fi)
client_token=$(if [ -f "$client_token_path" ] && [ -s "$client_token_path" ]; then cat "$client_token_path" ; fi)
accessor=$(if [ -f "$accessor_path" ] && [ -s "$accessor_path" ]; then cat "$accessor_path" ; fi)
}


token_exists() {
echo $client_token
echo $accessor
if [ -z "$client_token" ] || [ -z "$accessor" ]; then
  echo "$0 - Token or accessor does not exist"
  return 1
else
  echo 0
fi
}


token_is_valid() {
  echo "Checking token validity"
  token_lookup=$(curl -X POST \
       -H "X-Vault-Token: $client_token" \
       -w %{http_code} \
       --silent \
       --output /dev/null \
       -d '{"accessor":"'"$accessor"'"}'  \
       $vault_addr/v1/auth/token/lookup-accessor)
  if [ "$token_lookup" == "200" ]; then
    echo "$0 - Valid token found, exiting"
    return 0
  else
    echo "$0 - Invalid token found"
    return 1
  fi
}

fetch_token_and_accessor() {
curl -X POST \
     --silent \
     -d '{"role_id":"'"$role_id"'","secret_id":"'"$secret_id"'"}' \
     $vault_addr/v1/auth/approle/login |\
     tee >(jq --raw-output '.auth.accessor' > /tmp/accessor) >(jq --raw-output '.auth.client_token' > /tmp/client_token)
}


renew_token() {
  echo "Renewing token"
  curl -X POST \
       --silent \
       -H "X-Vault-Token: $client_token" \
       $vault_addr/v1/auth/token/renew-self | jq
}


wait_for_role_id_and_secret_id() {
while [ -z "$role_id" ] || [ -z "$secret_id" ]; do
  eval_vars
  echo "$0 - Waiting for role_id and secret_id"
  sleep 5
done
}


main() {
eval_vars
if token_exists; then
  if token_is_valid; then
    renew_token
    echo "$0 - Token renewed successfully"
    exit 0
  else
    wait_for_role_id_and_secret_id     ## need to write this
    fetch_token_and_accessor
    exit 0
  fi
elif [ -z "$role_id" ] || [ -z "$secret_id" ]; then
  # no role_id or secret_id so we wait
  wait_for_role_id_and_secret_id
  fetch_token_and_accessor
  exit 0
else
  # we have token and role_id and secret_id but no token
  # need to fetch token
  fetch_token_and_accessor
  exit 0
fi
}

main
