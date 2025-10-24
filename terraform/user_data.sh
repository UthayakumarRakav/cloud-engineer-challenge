#!/bin/bash
exec > /var/log/user_data.log 2>&1
set -ex

echo "=== Starting User Data Script ==="

# Update and install dependencies
apt-get update
apt-get install -y openjdk-11-jdk apache2

echo "=== Creating simple Java web application ==="

# Create a simple Java web server
cat > /opt/SimpleWebServer.java << 'EOF'
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.OutputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.time.LocalDateTime;

public class SimpleWebServer {
    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", new RootHandler());
        server.setExecutor(null);
        server.start();
        System.out.println("Server is running on port " + port);
    }
    
    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "<!DOCTYPE html>" +
                "<html>" +
                "<head><title>ALB + EC2 Demo</title>" +
                "<style>" +
                "body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }" +
                ".container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; backdrop-filter: blur(10px); max-width: 800px; margin: 0 auto; }" +
                "h1 { color: #fff; text-align: center; }" +
                ".status { background: #4CAF50; padding: 10px; border-radius: 5px; text-align: center; }" +
                ".info { background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; margin: 10px 0; }" +
                "</style></head>" +
                "<body>" +
                "<div class='container'>" +
                "<h1>🚀 ALB + EC2 Demo Application</h1>" +
                "<div class='status'>✅ Application is running successfully</div>" +
                "<div class='info'><strong>Server Time:</strong> " + LocalDateTime.now() + "</div>" +
                "<div class='info'><strong>Java Version:</strong> " + System.getProperty("java.version") + "</div>" +
                "<div class='info'><strong>Hostname:</strong> " + System.getenv("HOSTNAME") + "</div>" +
                "<h3>Architecture Overview:</h3>" +
                "<ul>" +
                "<li>Amazon EC2 Instance (Ubuntu 22.04)</li>" +
                "<li>Application Load Balancer</li>" +
                "<li>Apache HTTP Server as Reverse Proxy</li>" +
                "<li>Java Embedded HTTP Server on Port 8080</li>" +
                "</ul>" +
                "<p><em>This page is served by a Java application behind an ALB</em></p>" +
                "</div>" +
                "</body></html>";
            
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
            exchange.sendResponseHeaders(200, response.getBytes().length);
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
EOF

echo "=== Compiling Java application ==="
cd /opt
javac SimpleWebServer.java

echo "=== Creating systemd service ==="
cat > /etc/systemd/system/java-app.service << EOF
[Unit]
Description=Simple Java Web Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt
ExecStart=/usr/bin/java SimpleWebServer
Restart=always
RestartSec=5
Environment=HOSTNAME=\$(hostname)

[Install]
WantedBy=multi-user.target
EOF

echo "=== Starting Java application ==="
systemctl daemon-reload
systemctl enable java-app
systemctl start java-app

# Wait for Java app to start
echo "=== Waiting for Java app to start on port 8080 ==="
for i in {1..30}; do
    if nc -z localhost 8080; then
        echo "✅ Java application is running on port 8080"
        break
    fi
    echo "⏳ Waiting for Java app... ($i/30)"
    sleep 2
done

echo "=== Configuring Apache ==="
# Enable proxy modules
a2enmod proxy
a2enmod proxy_http
a2enmod headers

# Create Apache virtual host
cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    
    # Custom logging
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined_custom
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined_custom

    # Proxy configuration
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
    
    # Additional headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
</VirtualHost>
EOF

echo "=== Restarting Apache ==="
systemctl restart apache2

echo "=== Final checks ==="
# Check if services are running
if systemctl is-active --quiet java-app; then
    echo "✅ Java app service is running"
else
    echo "❌ Java app service failed"
    systemctl status java-app
fi

if systemctl is-active --quiet apache2; then
    echo "✅ Apache service is running"
else
    echo "❌ Apache service failed"
    systemctl status apache2
fi

# Test the application
echo "=== Testing application ==="
curl -f http://localhost:8080/ && echo "✅ Java app responds on port 8080"
curl -f http://localhost/ && echo "✅ Apache proxy works"

echo "=== User Data Script Completed Successfully ==="
echo "🎉 Setup complete! Access your application via the ALB DNS name."
echo "📊 Application will show a professional demo page with real-time information."