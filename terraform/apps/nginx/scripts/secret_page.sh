#!/usr/bin/env bash

echo "Obtaining root token and vault address from Consul..."
cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }
ROOT_TOKEN=$(cget root-token)
VAULT_ADDR=$(cat /tmp/consul-server-addr)


echo "Creating Template for SECRET PAGE..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl" << SECRET
{{with secret "secret/HomerSimpsonPassword"}}{{.Data.value}}{{end}}

  <html>
  <head>
      <title>SECRET PAGE</title>
      <META HTTP-EQUIV="refresh" CONTENT="5">
  </head>

  <body>
      <h1>HomerSimpsonPassword is <i>{{with secret "secret/HomerSimpsonPassword"}}{{.Data.value}}{{end}}</i></h1>
  </body>
  </html>
SECRET




echo "Install Consul template configuration file for secret page..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/consul-template.json" << EOF
consul = "127.0.0.1:8500"

vault {
  address = "http://$VAULT_ADDR:8200"
  token = "$ROOT_TOKEN"
}

template {
  source = "/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl"
  destination = "/var/www/html/secret.html"
}
EOF

echo "Starting Consul template service..."
sudo systemctl enable consul-template.service
sudo systemctl start consul-template
