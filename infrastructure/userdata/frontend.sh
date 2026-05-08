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

# ==========================================
# Generate runtime config dynamically (load balancer dns name will be injected by userdata script of load balancer)
# ==========================================

cat > /var/www/html/runtime-config.js <<EOF
window.__CONFIG__ = {
    API_BASE_URL: "${api_url}"
};
EOF

# ==========================================
# Configure nginx
# ==========================================

cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location = /runtime-config.js {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }
}
EOF

# Permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Restart nginx
systemctl restart nginx
systemctl enable nginx