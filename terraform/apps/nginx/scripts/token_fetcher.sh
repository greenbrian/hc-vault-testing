#!/bin/bash

set -e

# this script emulates the orchestration that would normally be
# performed by the following
#
# role_id being embedded during an image creation step
#
# secret_id being retrieved/embedded by an orchestration tool


cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

cget role_id > /tmp/role_id
cget secret_id > /tmp/secret_id
