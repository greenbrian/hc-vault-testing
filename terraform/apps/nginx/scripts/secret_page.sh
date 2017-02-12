#!/usr/bin/env bash


echo "Creating Template for SECRET PAGE..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl" << SECRET
  <html>
  <head>
      <title>SECRET PAGE</title>
      <META HTTP-EQUIV="refresh" CONTENT="5">
  </head>

{{with secret "secret/waycoolapp" }}
  <body>
      <h1>Homer Simpson SSN is <i>{{Data.HomerSimpsonSSN}}</i></h1>
      <h1>Mr Burns SSN is <i>{{Data.MrBurnsSSN}}</i></h1>
  </body>
  </html>
{{end}}
SECRET


echo "Install Consul template configuration file for secret page..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/consul-template.json" << EOF
consul {
  address = "127.0.0.1:8500"
}

vault {
  address = "http://active.vault.service.dc1.consul:8200"
  token = "/ramdisk/client_token"
}

template {
  source = "/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl"
  destination = "/var/www/html/secret.html"
}
EOF
