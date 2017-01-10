#!/usr/bin/env bash

set -e

# read role_id
ROLE_ID=$(cat /tmp/role_id)

# read secret_id
SECRET_ID=$(cat /tmp/secret_id)

echo "Login using AppRole to retrieve access token..."
curl -X POST \
     -d '{"role_id":"988a9dfd-ea69-4a53-6cb6-9d6b86474bba","secret_id":"37b74931-c4cd-d49a-9246-ccc62d682a25"}' \
     http://127.0.0.1:8200/v1/auth/approle/login | jq .
