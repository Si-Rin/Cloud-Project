#!/bin/bash

# Update packages
apt update -y

# Install dependencies
apt install -y git nginx curl

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Go to web root
cd /var/www/html

# Remove default files
rm -rf *

# Clone frontend repository
git clone https://github.com/alaabenhmida/client.git app

# Build Angular app
cd app

npm install
npm run build

# Copy Angular build
cp -r dist/client/browser/* /var/www/html/

# Configure nginx
cat > /etc/nginx/sites-available/default <<EOF
# Serve the Angular app on port 80
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

# Proxy localhost:3000 to the real backend ALB
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