#!/bin/bash

# Update packages
apt update -y

# Install dependencies
apt install -y git nginx curl

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Add swap space to prevent OOM kill during Angular build
fallocate -l 2G /swapfile        # no sudo — userdata runs as root
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Go to web root
cd /var/www/html

# Remove default files
rm -rf *

# Clone frontend repository
git clone https://github.com/alaabenhmida/client.git app

# Build Angular app
cd app
npm install                       # was missing before build
npm run build

# Copy Angular build
cp -r dist/*/browser/* /var/www/html/   # wildcard instead of hardcoded "client"

# Configure nginx
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

server {
    listen 3000;
    server_name localhost;

    location / {
        proxy_pass ${api_url};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Restart nginx
systemctl restart nginx
systemctl enable nginx