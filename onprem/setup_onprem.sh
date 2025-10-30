#!/bin/bash
# Simulates on-premise Ubuntu server setup for legacy app

set -e

echo "🔧 Setting up on-premise server..."

# Network config (simulated static IP)
cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.10.10/24]
      gateway4: 192.168.10.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF

netplan apply

# Install legacy stack
apt-get update
apt-get install -y apache2 openjdk-11-jre mysql-server wget

# Install Tomcat 9
apt-get install -y tomcat9

# Secure MySQL (basic)
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'SecurePass123!';"
mysql -e "CREATE DATABASE IF NOT EXISTS legacy_app;"
mysql -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'AppPass123!';"
mysql -e "GRANT ALL PRIVILEGES ON legacy_app.* TO 'appuser'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Download and deploy Joget DX WAR (Community Edition)
wget -O /tmp/joget.war https://dev.joget.org/downloads/7.0/joget-dx7-community-7.0.33.war
mv /tmp/joget.war /var/lib/tomcat9/webapps/jw.war
chown tomcat:tomcat /var/lib/tomcat9/webapps/jw.war

# Configure UFW firewall
ufw allow 80/tcp
ufw allow 8080/tcp   # Allow Tomcat/Joget web interface
ufw allow 3306/tcp  # Temporarily open for migration; will restrict later
ufw allow OpenSSH
ufw --force enable

# Simulate static site deployment
echo "<html><body><h1>Legacy On-Prem App</h1></body></html>" > /var/www/html/index.html

# For AWS connectivity: install strongSwan (IPsec VPN)
apt-get install -y strongswan

# Start Tomcat (ensure Joget auto-deploys)
systemctl restart tomcat9

echo "✅ On-premise setup complete."
echo "Next: Configure IPsec tunnel to AWS (see README for steps)."
