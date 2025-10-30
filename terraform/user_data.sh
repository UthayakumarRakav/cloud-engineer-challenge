#!/bin/bash
set -ex

# Output all commands and errors to user-data-exec.txt for debugging
mkdir -p /var/www/html
exec > >(tee /var/www/html/user-data-exec.txt) 2>&1

echo "=== Starting Joget DX Platform (Bundle) User Data Script ==="

# Update and install dependencies
apt-get update
apt-get install -y openjdk-11-jdk wget apache2

# Download and extract Joget DX platform
wget -O /tmp/joget.tar.gz "https://sourceforge.net/projects/jogetworkflow/files/joget-linux-9.0.1.tar.gz/download"
mkdir -p /opt/joget
# Extract and remove tarball
 tar -xzf /tmp/joget.tar.gz -C /opt/joget --strip-components=1
rm /tmp/joget.tar.gz

# Start Joget (runs its own Tomcat on 8080)
nohup /opt/joget/joget-start.sh > /var/www/html/joget-start.log 2>&1 &

# Configure Apache as a reverse proxy to Joget's Tomcat
 a2enmod proxy
 a2enmod proxy_http
 a2enmod headers

cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined_custom
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined_custom
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
</VirtualHost>
EOF

systemctl restart apache2

# Output a directory listing and log file info for debugging
ls -lh /opt/joget > /var/www/html/joget-dir.txt
ls -lh /opt/joget/apache-tomcat-*/logs/ > /var/www/html/joget-tomcat-logs.txt || true
tail -n 50 /var/www/html/joget-start.log > /var/www/html/joget-start-tail.txt || true

echo "=== Joget DX Platform Deployment Complete ==="
echo "Access the Joget DX app at http://<INSTANCE_IP_OR_ALB>:80/"
