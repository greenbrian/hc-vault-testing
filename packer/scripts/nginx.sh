#!/usr/bin/env bash

echo "Installing Nginx..."
sudo mkdir -p /var/log/nginx
#sudo chown  /var/log/nginx
sudo chmod -R 755 /var/log/nginx
sudo apt-get install -y -q nginx
sudo mkdir /etc/nginx/ssl

echo "Configuring Nginx firewall rules..."
sudo iptables -I INPUT -s 0/0 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
sudo netfilter-persistent reload

sudo bash -c "cat >/etc/nginx/sites-available/default" <<'SECRET'

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    ssl_certificate     /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.crt;

    root /var/www/html;

    # Add index.php to the list if you are using PHP
    index index.html index.htm index.nginx-debian.html secret.html;

    server_name _;

    location / {
       # First attempt to serve request as file, then
       # as directory, then fall back to displaying a 404.
       try_files $uri $uri/ =404;
     }
}

SECRET
