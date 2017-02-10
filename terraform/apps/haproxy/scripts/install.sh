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

# register services and checks in consul
sudo bash -c "cat >/etc/systemd/system/consul.d/haproxy.json" << HAPROXY
{"service": {
  "name": "haproxy",
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
        "script": "service haproxy status",
        "interval": "30s"
      }]
    }
}
HAPROXY


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
        "interval": "300s"
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
sudo hostname $new_hostname
sudo bash -c "cat >>/etc/hosts" << HOSTS
127.0.1.1 $new_hostname
HOSTS
sudo bash -c "cat >>/etc/hosts" << NEWHOSTNAME
$new_hostname
NEWHOSTNAME
