#!/usr/bin/env bash
set -e

sudo bash -c "cat >/etc/consul.d/consul.json" << EOF
{
    "datacenter": "dc1",
    "data_dir": "/opt/consul/data",
    "retry_join": ["provider=aws tag_key=env tag_value=hcvt-demo"]
}
EOF
chmod 0644 /etc/consul.d/consul.json

# register services and checks in consul
bash -c "cat >/etc/consul.d/haproxy.json" << HAPROXY
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

bash -c "cat >/etc/consul.d/haproxy-ssl.json" << HAPROXY-SSL
{"service": {
  "name": "haproxy-ssl",
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
        "script": "service haproxy status",
        "interval": "30s"
      }]
    }
}
HAPROXY-SSL


bash -c "cat >/etc/consul.d/system.json" << SYSTEM
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
hostname $${new_hostname}
bash -c "cat >>/etc/hosts" << HOSTS
127.0.1.1 $new_hostname
HOSTS
bash -c "cat >>/etc/hosts" << NEWHOSTNAME
$${new_hostname}
NEWHOSTNAME

systemctl enable consul.service
systemctl start consul
systemctl enable consul-template.service
systemctl start consul-template
