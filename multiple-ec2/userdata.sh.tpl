#!/bin/bash
apt update -y
apt install nginx -y
systemctl enable nginx
systemctl start nginx

echo "<h1>Hello from Terraform EC2</h1>" > /var/www/html/index.html
