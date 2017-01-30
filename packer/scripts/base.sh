#!/usr/bin/env bash

# update system and install packages
sudo DEBIAN_FRONTEND=noninteractive apt-get update --yes -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --yes -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes \
--force-yes -q curl wget unzip iptables-persistent jq
