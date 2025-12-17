#!/bin/bash
# Quick setup for Docker and AWS CLI on EC2
# Usage: ssh -i your-key.pem ec2-user@YOUR_INSTANCE_IP << 'EOF'
# bash /tmp/setup.sh
# EOF

set -e

echo "🚀 Installing Docker and AWS CLI..."

# Update and install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "✅ Docker: $(docker --version)"
echo "✅ AWS CLI: $(aws --version)"
echo "✅ Docker Compose: $(docker-compose --version)"
echo ""
echo "⚠️  Exit SSH and reconnect for Docker permissions to take effect!"
