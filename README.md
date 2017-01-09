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


## TODO


Vault - start, init, unseal
Vault - configure AppRole

App - install consul-template
App - configure systemd to retrieve

# vault init -key-shares=1 -key-threshold=1
Unseal Key 1 (hex)   : d2c1aaa66623c4d2b5cff5b97a0d08338ccd2a3bcd88e67cd1de83c82271f642
Unseal Key 1 (base64): 0sGqpmYjxNK1z/W5eg0IM4zNKjvNiOZ80d6DyCJx9kI=
Initial Root Token: 7883b5c8-9f15-9f05-af27-9a0769f76e4e

Vault initialized with 1 keys and a key threshold of 1. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 1 of these keys
to unseal it again.

Vault does not store the master key. Without at least 1 keys,
your Vault will remain permanently sealed.
