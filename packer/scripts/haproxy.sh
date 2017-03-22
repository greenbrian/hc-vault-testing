#!/usr/bin/env bash

echo "Installing HAProxy..."
sudo apt-get install -y -q haproxy

echo "Configuring HAProxy firewall rules..."
sudo iptables -I INPUT -s 0/0 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
sudo netfilter-persistent reload

echo "Install Consul template configuration file for HAProxy..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/templates/haproxy.cfg.ctmpl" << HAPROXY
global
   log /dev/log local0
   log /dev/log local1 notice
   chroot /var/lib/haproxy
   stats socket /run/haproxy/admin.sock mode 660 level admin
   stats timeout 30s
   user haproxy
   group haproxy
   daemon

defaults
   log global
   mode http
   option httplog
   option dontlognull
   timeout connect 5000
   timeout client 50000
   timeout server 50000

frontend http_front
   bind *:80
   stats uri /haproxy?stats
   default_backend http_back

backend http_back
   balance roundrobin{{range service "nginx"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}

frontend https_front
   mode tcp
   bind *:443
   default_backend https_back

backend https_back
   mode tcp
   balance roundrobin{{range service "nginx-ssl"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}

listen vault
   bind 0.0.0.0:8200
   balance roundrobin
   option httpchk GET /v1/sys/health{{range service "vault"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}

HAPROXY

echo "Configuring Consul Template for HAProxy..."
sudo bash -c "cat >/etc/systemd/system/consul-template.d/consul-template.json" << EOF
consul = "127.0.0.1:8500"
template {
  source = "/etc/systemd/system/consul-template.d/templates/haproxy.cfg.ctmpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command = "service haproxy reload"
  command_timeout = "30s"
  backup = true
}
EOF
