#!/bin/bash
# Deployment script for EC2

echo "=== Deploying website files ==="

# Copy files from /tmp/website to web server
if [ -d "/tmp/website" ]; then
    sudo cp -r /tmp/website/* /var/www/html/
    echo "Files deployed successfully"
else
    echo "Website directory not found"
fi

# Restart Apache
sudo systemctl restart httpd

# Print status
echo "=== Deployment complete ==="
echo "Website accessible at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
