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

One of Vault's use cases is to obtain secrets for use within an application on a server. A node can authenticate with Vault using a token to obtain the required secrets, but a secure introduction of that authenticating token is still required. AppRole functionality is one method of obtaining that token.

More on AppRole
