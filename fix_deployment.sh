#!/bin/bash

# This script fixes the deployment issue on EC2
# Run this to ensure Docker daemon is running and credentials are set

echo "=== Fixing Deployment Issues ==="
echo ""

# 1. Ensure Docker is running
echo "1. Starting Docker daemon..."
sudo systemctl start docker || true
sleep 2

# 2. Configure AWS credentials using EC2 IAM role
echo "2. Testing AWS IAM role credentials..."
if curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | grep -q "[a-zA-Z]"; then
    echo "   IAM role found on EC2!"
    echo "   AWS CLI should automatically use it."
else
    echo "   WARNING: No IAM role found on EC2"
fi

# 3. Test AWS CLI
echo ""
echo "3. Testing AWS CLI access..."
aws sts get-caller-identity || echo "Note: AWS credentials may need configuration"

# 4. Stop any old containers
echo ""
echo "4. Cleaning up old containers..."
sudo docker stop portfolio-website || true
sudo docker rm portfolio-website || true

# 5. Pull latest image from ECR
echo ""
echo "5. Pulling latest image from ECR..."
IMAGE_URI="798541564412.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest"

# Login to ECR using IAM role
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 798541564412.dkr.ecr.us-east-1.amazonaws.com

# Pull the image
sudo docker pull $IMAGE_URI || echo "ERROR: Failed to pull image"

# 6. Start container
echo ""
echo "6. Starting new container..."
sudo docker run -d \
  --name portfolio-website \
  --restart always \
  -p 5000:5000 \
  $IMAGE_URI

# 7. Verify
sleep 3
echo ""
echo "=== Deployment Status ==="
echo "Docker containers:"
sudo docker ps
echo ""
echo "Testing website locally..."
curl -s http://localhost:5000 | head -c 200
echo ""
echo ""
echo "Done! Your website should be updated."
