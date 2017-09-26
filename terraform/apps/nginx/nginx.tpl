#!/usr/bin/env bash
set -e

mkdir /ramdisk
mount -t tmpfs -o size=20M,mode=700 tmpfs /ramdisk

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-retry-join-ec2-tag-key=env \
-retry-join-ec2-tag-value=hcvt-demo \
-data-dir=/opt/consul/data "
EOF

chown root:root /etc/default/consul
chmod 0644 /etc/default/consul

echo "Configuring Vault environment..."
sudo bash -c "cat >/etc/profile.d/vault.sh" << 'VAULTENV'
export VAULT_ADDR=http://active.vault.service.dc1.consul:8200
if [ "`id -u`" -eq 0 ]; then
  export VAULT_TOKEN=$(cat /ramdisk/client_token)
fi
VAULTENV
sudo chmod 755 /etc/profile.d/vault.sh


# generate static site
HOST=$(hostname -f)
KERNEL=$(uname -a)
TITLE="System Information for $${HOST}"
RIGHT_NOW=$(date +"%x %r %Z")
TIME_STAMP="Updated on $${RIGHT_NOW} by $${USER}"
AWSPUBHOST=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
AWSPUBIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

sudo bash -c "cat >/var/www/html/index.nginx-debian.html" << EOF
  <html>
  <head>
      <title>$TITLE</title>
      <META HTTP-EQUIV="refresh" CONTENT="5">
  </head>

  <body>
      <h1>$TITLE</h1>
      <p>$TIME_STAMP</p>
      <p>$HOST</p>
      <p>$KERNEL</p>
      <p>AWS public hostname is $AWSPUBHOST</p>
      <p>AWS public IP is $AWSPUBIP</p>
  </body>
  </html>
EOF

# register services and checks in consul
sudo bash -c "cat >/etc/systemd/system/consul.d/nginx.json" << NGINX
{"service": {
  "name": "nginx",
  "tags": ["web"],
  "port": 80,
    "checks": [
      {
        "id": "GET",
        "script": "curl localhost >/dev/null 2>&1",
        "interval": "10s"
      },
      {
        "id": "HTTP-TCP",
        "name": "HTTP TCP on port 80",
        "tcp": "localhost:80",
        "interval": "10s",
        "timeout": "1s"
      },
        {
        "id": "OS service status",
        "script": "service nginx status",
        "interval": "30s"
      }]
    }
}
NGINX

sudo bash -c "cat >/etc/systemd/system/consul.d/nginx-ssl.json" << NGINX-SSL
{"service": {
  "name": "nginx-ssl",
  "tags": ["web"],
  "port": 443,
    "checks": [
      {
        "id": "GET",
        "script": "curl localhost >/dev/null 2>&1",
        "interval": "10s"
      },
      {
        "id": "HTTPS-TCP",
        "name": "HTTPS TCP on port 443",
        "tcp": "localhost:443",
        "interval": "10s",
        "timeout": "1s"
      },
        {
        "id": "OS service status",
        "script": "service nginx status",
        "interval": "30s"
      }]
    }
}
NGINX-SSL

sudo bash -c "cat >/etc/systemd/system/consul.d/system.json" << SYSTEM
{
    "checks": [
      {
        "id": "report CPU load",
        "name": "CPU Load",
        "script": "(printf '1m  5m  15m  cur/total  last-pid\n'; cat /proc/loadavg) | column -t",
        "interval": "60s"
      },
      {
        "id": "check RAM usage",
        "name": "RAM usage",
        "script": "free -m",
        "interval": "30s"
      },
      {
        "id": "test internet connectivity",
        "name": "ping",
        "script": "ping -c1 google.com >/dev/null",
        "interval": "30s"
      }]
}
SYSTEM


new_hostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
sudo hostname $${new_hostname}
sudo bash -c "cat >>/etc/hosts" << HOSTS
127.0.1.1 $new_hostname
HOSTS
sudo bash -c "cat >>/etc/hosts" << NEWHOSTNAME
$${new_hostname}
NEWHOSTNAME





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


systemctl enable consul.service
systemctl start consul

sleep 5



bash -c "/usr/local/bin/token_mgmt.sh" << TOKEN_MGMT
#!/usr/bin/env bash

set -e

vault_addr="http://active.vault.service.dc1.consul:8200"
role_id_path="/tmp/role_id"
secret_id_path="/tmp/secret_id"
client_token_path="/ramdisk/client_token"

if [ -s "$client_token_path" ]; then
  echo "$0 - Token exists"
  exit 0
else
  while [ ! -s "$role_id_path" ] || [ ! -s "$secret_id_path" ]; do
    echo "$0 - Waiting for role_id and secret_id"
    sleep 5
  done
  client_token=$(curl -X POST \
  --silent \
  -d '{"role_id":"'"$(cat $role_id_path)"'","secret_id":"'"$(cat $secret_id_path)"'"}' \
  $vault_addr/v1/auth/approle/login |  \
  jq --raw-output '.auth.client_token' )
  echo "VAULT_TOKEN=${client_token}" > $client_token_path
  exit 0
fi
TOKEN_MGMT
chmod +x /usr/local/bin/token_mgmt.sh



bash -c "/lib/systemd/system/token_mgmt.service" << TOKEN_MGMT_SVC
[Unit]
Description=Token Management script for Vault & Consul-template

[Service]
Type=simple
ExecStart=/usr/local/bin/token_mgmt.sh
User=root
Group=root
TOKEN_MGMT_SVC

bash -c "/lib/systemd/system/token_mgmt.timer" << TOKEN_MGMT_TIMER
[Unit]
Description=Runs token_mgmt.sh once a minute

[Timer]
# Time to wait after booting before we run first time
OnBootSec=1min
# Time between running each consecutive time
OnUnitActiveSec=1min
Unit=token_mgmt.service

[Install]
WantedBy=multi-user.target
TOKEN_MGMT_TIMER

systemctl start token_mgmt.timer
systemctl enable token_mgmt.timer

bash -c "/tmp/token_fetcher.sh" << TOKEN_FETCHER
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
TOKEN_FETCHER

chmod +x /tmp/token_fetcher.sh
echo /tmp/token_fetcher.sh | at now + 1 min

systemctl enable consul-template.service
systemctl start consul-template
