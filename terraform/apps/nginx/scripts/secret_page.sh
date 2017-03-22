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

echo "Creating Template for private key..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/templates/cert.ctmpl" << CERT
{{ with secret "vault-ca-intermediate/issue/example-dot-com" "common_name=foo.example.com" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
CERT


sudo chmod +x /etc/systemd/system/consul-template.d/cert.sh

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
  source = "/etc/systemd/system/consul-template.d/templates/cert.ctmpl"
  destination = "/etc/nginx/ssl/example.com.crt"
  command = "service nginx restart"
}


template {
  source = "/etc/systemd/system/consul-template.d/templates/secret.html.ctmpl"
  destination = "/var/www/html/secret.html"
}
EOF
