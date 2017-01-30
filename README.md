# hc-vault-testing
Testing HashiCorp Vault functionality

# Objectives

Goal of this repository is to provide an environment to demonstrate and test initial secret introduction in a Linux environment, using HashiCorp Vault, and Consul-template on a local node.

# Architecture
The Vagrantfile can spin up a single node running Vault with a simple example application.

This is a minimal environment without high availability or TLS enabled purely to test Vault AppRole functionality for managing the initial secret (token) introduction.


## Vault AppRole Testing

### Summary
One of Vault's use cases is to obtain secrets for use within an application on a server. A node can authenticate with Vault using a token to obtain the required secrets, but a secure introduction of that authenticating token is still required. AppRole functionality is one method of obtaining that token.

### Overview

The below are end to end steps on using AppRole (pull method) for managing your secret introduction. This process is flexible and open to various interpretations based on environment constraints, and various tools used.

1. Enable AppRole on Vault
2. Write secrets
3. Create policy mapping specific AppRole 'foo' to secrets
4. Create specific AppRole 'foo', associated with policy, and other constraints (bound CIDR list allowed for login requests, secret_id number uses, secret_id ttl, etc)
5. Read `role_id` for AppRole 'foo'. This is a long lasting role identifier for this AppRole (foo). Akin to an email address or user ID. This information is not sensitive in and of itself, but you would not want to share it publicly.
6. Embed the `role_id` within your operating system image. This can be done via Packer, or during provisioning steps.
7. Read `secret_id` for AppRole 'foo'. This token should be treated as sensitive, and is meant to be short lived. Using response wrapping here is a good idea as it protects the `secret_id` during the delivery process.
8. Deploy the `secret_id` during orchestration activities (during application deployment, configuration management or some steps post provisioning). An example might be a deploy using an orchestrator capable of API calls, with the first step being the retrieval of the `secret_id` from Vault.
9. Use a script or process that performs the login operation that makes a request to Vault combining `role_id` + `secret_id` to obtain a token. This script should also perform maintenance of the token, ensuring it is renewed on a regular basis.  I have an example shell script at scripts/vault-approle-token.sh that can be executed via systemd that can perform this process.
10. Consul-template or envconsul can now use the obtained token to make requests to Vault for secrets.

TODO:
- Finish and test vault-approle-token.sh script
- Setup systemd to run vault-approle-token.sh as a service

### Scripts
Scripts used in this repository

    ./vault-approle-setup.sh   # this configures approle and generates role_id and secret_id
    ./vault-approle-token.sh   # this is a script that maintains a token on a system to be used by consul-template, envconsul and so forth
    ./vault-cleanup.sh         # restarts and reinitializes Vault, clears artifacts - startover from scratch

### Usage

To bring up the Ubuntu vm

    vagrant up

To test AppRole

    vagrant ssh
    /vagrant/vault-approle-setup.sh
    /vagrant/vault-approle-token.sh

### Current Status

The above usage steps work. Items to be completed:

1. Token management script needs to be managed by systemd
2. Script logic calculating token renewal period needs to be completed.
3. Need to complete AppRole push example

### Token management script logic


```
                         +----------------+
                         | does token and |
                         | token_accessor |
                         | exist?         |
                         +----------------+
           +-----+               |            +----+
           | yes | <------------------------> | no |
           +-----+                            +----+
              |                                  |
              v                                  |
                                                 |
     +---------------+                           |
     | Is the token  |                           |
     | still valid?  |                           |
     |               |                           v
     +---------------+
                |                     +-------------------------+
                |                     | use role_id + secret_id |
     +-----+    |      +----+         | to fetch new token and  |
     | yes | <-------> | no +-------> | token_accessor          |
     +-----+           +----+         +-------------------------+
        |                                     |
        |                                     |
        v                                     v

     +--------------------------------------------+
     |  Get creation_ttl + current ttl and sleep  |
     |  for (creation_ttl/ttl)/2 and then trigger |
     |  token renewal. Rinse & repeat.            |
     +--------------------------------------------+
```


#### AppRole pull configuration (TODO)

    vagrant ssh
    cd /vagrant/scripts
    ./vault-approle-setup.sh
    ./vault
