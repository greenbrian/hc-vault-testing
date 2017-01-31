#!/usr/bin/env bash
set -e

# Read from the file we created
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-join=${CONSUL_JOIN} \
-data-dir=/opt/consul/data"
EOF

sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul


# generate static site
HOST=$(hostname -f)
KERNEL=$(uname -a)
TITLE="System Information for $HOST"
RIGHT_NOW=$(date +"%x %r %Z")
TIME_STAMP="Updated on $RIGHT_NOW by $USER"
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
