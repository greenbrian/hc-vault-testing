# hc-vault-testing
Testing HashiCorp Vault functionality

# Objectives

Goal of this repository is to provide an environment to demonstrate and test initial secret introduction in a Linux environment, using HashiCorp Vault, and Consul-template on a local node.

# Architecture
The Vagrantfile can spin up a single node running Vault with a simple example application.

This is a minimal environment without high availability or TLS enabled purely to test Vault AppRole functionality for managing the initial secret (token) introduction.

# Process

To bring up the Ubuntu machine you can use the regex method:

    vagrant up

## Vault AppRole Testing

### Summary
One of Vault's use cases is to obtain secrets for use within an application on a server. A node can authenticate with Vault using a token to obtain the required secrets, but a secure introduction of that authenticating token is still required. AppRole functionality is one method of obtaining that token.

### Scripts
Scripts used in this repository

    ./vault-approle-setup.sh   # this configures approle and generates role_id and secret_id
    ./vault-approle-token.sh   # this is a script that maintains a token on a system to be used by consul-template, envconsul and so forth
    ./vault-cleanup.sh         # restarts and reinitializes Vault, clears artifacts - startover from scratch

### Usage

#### AppRole pull configuration

    vagrant ssh
    cd /vagrant/scripts
    ./vault-approle-setup.sh
    ./vault

This will
