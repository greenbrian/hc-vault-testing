#!/usr/bin/env bash

set -e

vault_addr="http://127.0.0.1:8200"
role_id=$(if [ -f /tmp/role_id ] && [ -s /tmp/role_id ]; then cat /tmp/role_id ; fi)
secret_id=$(if [ -f /tmp/secret_id ] && [ -s /tmp/secret_id ]; then cat /tmp/secret_id ; fi)
client_token=$(if [ -f /tmp/client_token ] && [ -s /tmp/client_token ]; then cat /tmp/client_token ; fi)
accessor=$(if [ -f /tmp/accessor ] && [ -s /tmp/accessor ]; then cat /tmp/accessor ; fi)

echo "role_id is $role_id"
echo "secret_id is $secret_id"
echo "client_token is $client_token"
echo "accessor is $accessor"


token_is_valid() {
  echo "checking token validity"
  token_lookup=$(curl -X POST \
       -H "X-Vault-Token: $client_token" \
       -w %{http_code} \
       --silent \
       --output /dev/null \
       -d '{"accessor":"'"$accessor"'"}'  \
       $vault_addr/v1/auth/token/lookup-accessor)
  echo $token_lookup
  if [ "$token_lookup" == "200" ]; then
    return 0
  else
    return 1
    echo "INVALID TOKEN!"
  fi
}

fetch_token_and_accessor() {
curl -X POST \
     --silent \
     -d '{"role_id":"'"$role_id"'","secret_id":"'"$secret_id"'"}' \
     $vault_addr/v1/auth/approle/login |\
     tee >(jq --raw-output '.auth.accessor' > /tmp/accessor) >(jq --raw-output '.auth.client_token' > /tmp/client_token)
}


token_renewal() {
  echo "renewing token!"
  echo "client token is $client_token"
  curl -X POST \
       --silent \
       -H "X-Vault-Token: $client_token" \
       -d '{"token":"'"$client_token"'"}'  \
       $vault_addr/v1/auth/token/renew | jq
}

wait_half_life() {
  # will sort this out when the rest works
  sleep 5
}


main(){
while true
do
    if [ ! -z ${role_id+x} ] || [ ! -z ${secret_id+x} ]; then
        # continue if both role_id and secret_id exist
        if [ ! -z ${client_token+x} ] || [ ! -z ${accessor+x} ]; then
            # if both client_token and accessor exist
            if token_is_valid; then
                logger "$0 - Found valid token."
                wait_half_life
                token_renewal
                logger "$0 - Token renewed successfully."
            else
                fetch_token_and_accessor
                logger "$0 - Token retrieved successfully."
                client_token=$(if [ -f /tmp/client_token ] && [ -s /tmp/client_token ]; then cat /tmp/client_token ; fi)
                accessor=$(if [ -f /tmp/accessor ] && [ -s /tmp/accessor ]; then cat /tmp/accessor ; fi)
                wait_half_life
                token_renewal
            fi
        else
            fetch_token_and_accessor
            logger "$0 - Token retrieved successfully."
            wait_half_life
            token_renewal
        fi
    else
      logger "$0 - ERROR Vault role_id or secret_id do not exist."
      # wait for role_id and secret_id to be populated
      sleep 300
    fi
done
}

main
