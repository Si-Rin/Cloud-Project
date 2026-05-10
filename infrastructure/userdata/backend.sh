#!/bin/bash

# Update packages
apt update -y

# Install dependencies
apt install -y git curl mysql-client netcat-openbsd

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PM2 globally
npm install -g pm2

# Go to ubuntu home
cd /home/ubuntu

# Clone backend repository
git clone https://github.com/alaabenhmida/backend.git app

# Go to backend app
cd app

# Install dependencies
npm install

# Create environment variables file
cat > .env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
PORT=3000
EOF

# Wait for RDS to accept connections
echo "Waiting for RDS to accept connections..."
# Alternatively, you can use the mysql command to check if the database is ready:
until mysql -h ${db_host} -u ${db_user} -p${db_pass} -e "SELECT 1" &>/dev/null; 
do
  sleep 5
done
echo "Database ready."

# Start backend with PM2
pm2 start npm --name backend -- start

# Enable PM2 on startup
pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save