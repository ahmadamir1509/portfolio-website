#!/bin/bash
# Docker Setup Script for EC2 Instance
# Run this on your EC2 instance: bash <(curl -s https://your-raw-github-url/setup-docker-ec2.sh)

set -e

echo "🚀 Setting up Docker and AWS CLI on EC2..."

# Update system
echo "📦 Updating system packages..."
sudo yum update -y

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install AWS CLI v2
echo "☁️  Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Docker Compose (optional, for reference)
echo "📝 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
echo ""
echo "✅ Verification:"
echo "Docker version:"
docker --version
echo ""
echo "AWS CLI version:"
aws --version
echo ""
echo "Docker Compose version:"
docker-compose --version

echo ""
echo "🎉 Setup complete!"
echo ""
echo "⚠️  IMPORTANT: Log out and log back in to apply Docker group permissions:"
echo "   exit"
echo "   ssh -i your-key.pem ec2-user@your-instance-ip"
echo ""
echo "Then test with: docker ps"
