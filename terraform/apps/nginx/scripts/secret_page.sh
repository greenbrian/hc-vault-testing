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
      <h1>User1 SSN is <i>{{.Data.User1SSN}}</i></h1>
      <h1>User2 SSN is <i>{{.Data.User2SSN}}</i></h1>
  </body>
  </html>
{{end}}
SECRET


echo "Install Consul template configuration file for secret page..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/consul-template.json" << EOF

consul {
  address = "127.0.0.1:8500"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }
}


vault {
  address = "http://active.vault.service.dc1.consul:8200"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }
}

template {
  source = "/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl"
  destination = "/var/www/html/secret.html"
}
EOF
