#!/bin/bash

# Update packages
apt update -y

# Install dependencies
apt install -y git nginx curl

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Add swap space to prevent OOM kill during Angular build
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Go to web root
cd /var/www/html

# Remove default files
rm -rf *

# Clone frontend repository
git clone https://github.com/alaabenhmida/client.git app

# Replace hardcoded localhost with real ALB URL in TypeScript source (before build)
sed -i "s|http://localhost:3000|${api_url}|g" app/src/app/services/user.service.ts

# Build Angular app
cd app
npm install
npm run build

# Copy Angular build
cp -r dist/*/browser/* /var/www/html/

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
EOF

# Permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Restart nginx
systemctl restart nginx
systemctl enable nginx