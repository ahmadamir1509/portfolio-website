#!/bin/bash
# Direct deployment fix - executes all commands

ssh -i "ec2-key-temp.pem" -o StrictHostKeyChecking=no ec2-user@98.93.75.181 << 'EOFREMOTE'

echo "=== STARTING DEPLOYMENT FIX ==="
echo ""

# Ensure Docker is running
echo "Starting Docker daemon..."
sudo systemctl start docker
sleep 1

# Check if we need AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "WARNING: AWS credentials not found. This may be using IAM role."
fi

# Clean up old containers
echo "Cleaning up old containers..."
sudo docker stop portfolio-website || true
sudo docker rm portfolio-website || true

# Pull latest image
echo "Pulling latest image from ECR..."
IMAGE_URI="798541564412.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest"

# Try to login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 798541564412.dkr.ecr.us-east-1.amazonaws.com || \
    echo "Note: ECR login may fail if credentials not configured"

# Pull image
echo "Pulling image..."
sudo docker pull $IMAGE_URI || echo "ERROR: Could not pull image"

# Start new container
echo "Starting new container..."
sudo docker run -d \
  --name portfolio-website \
  --restart always \
  -p 5000:5000 \
  $IMAGE_URI || echo "ERROR: Could not start container"

# Wait and check
sleep 3
echo ""
echo "=== DEPLOYMENT STATUS ==="
echo "Running containers:"
sudo docker ps || echo "Could not list containers"

echo ""
echo "Testing website locally..."
curl -s http://localhost:5000 | head -c 100 || echo "Website not responding"

echo ""
echo "=== DONE ==="
echo "Docker daemon is running"
echo "Container should be deployed"
echo "Website should be accessible at http://98.93.75.181:5000"

EOFREMOTE
