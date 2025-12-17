#!/bin/bash

# Quick Diagnostic Script for Portfolio Website Deployment
# Run this to check what's working and what's not

echo "============================================"
echo "Portfolio Website Deployment Diagnostic"
echo "============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Check Docker Daemon${NC}"
echo "--------------------------------"
if sudo systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is NOT running${NC}"
    echo "   Fix: sudo systemctl start docker"
fi
echo ""

echo -e "${YELLOW}Step 2: Check Docker Access${NC}"
echo "--------------------------------"
if sudo docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Can access Docker daemon${NC}"
    echo "   Running containers:"
    sudo docker ps --format "table {{.Names}}\t{{.Status}}"
else
    echo -e "${RED}❌ Cannot access Docker daemon${NC}"
    echo "   Fix: sudo usermod -aG docker ec2-user"
fi
echo ""

echo -e "${YELLOW}Step 3: Check AWS Credentials${NC}"
echo "--------------------------------"
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    echo "   AWS Account: $ACCOUNT"
else
    echo -e "${RED}❌ AWS credentials NOT configured${NC}"
    echo "   Fix: Configure ~/.aws/credentials with access key and secret"
fi
echo ""

echo -e "${YELLOW}Step 4: Check ECR Access${NC}"
echo "--------------------------------"
if aws ecr describe-repositories --repository-names portfolio-website --region us-east-1 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ECR repository found${NC}"
    IMAGES=$(aws ecr describe-images --repository-name portfolio-website --region us-east-1 --query 'length(imageDetails)' --output text)
    echo "   Images in ECR: $IMAGES"
else
    echo -e "${RED}❌ Cannot access ECR repository${NC}"
    echo "   Fix: Check AWS credentials and permissions"
fi
echo ""

echo -e "${YELLOW}Step 5: Check Container Status${NC}"
echo "--------------------------------"
if sudo docker ps | grep portfolio-website > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Container is RUNNING${NC}"
    CONTAINER_ID=$(sudo docker ps --filter "name=portfolio-website" --format "{{.ID}}")
    CREATED=$(sudo docker ps --filter "name=portfolio-website" --format "{{.RunningFor}}")
    echo "   Container ID: $CONTAINER_ID"
    echo "   Running for: $CREATED"
else
    echo -e "${RED}❌ Container is NOT running${NC}"
    
    # Check if container exists but is stopped
    if sudo docker ps -a | grep portfolio-website > /dev/null 2>&1; then
        echo "   ⚠️  Container exists but is stopped"
        echo "   Last logs:"
        sudo docker logs portfolio-website | tail -5
    else
        echo "   ⚠️  Container doesn't exist at all"
    fi
fi
echo ""

echo -e "${YELLOW}Step 6: Check Website Response${NC}"
echo "--------------------------------"
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Website is responding on port 5000${NC}"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000)
    echo "   HTTP Status: $STATUS"
else
    echo -e "${RED}❌ Website NOT responding${NC}"
    echo "   Fix: Check container logs with: sudo docker logs portfolio-website"
fi
echo ""

echo "============================================"
echo "Diagnostic Complete"
echo "============================================"
echo ""
echo "Next steps based on your results:"
echo "- If Docker daemon is not running: sudo systemctl start docker"
echo "- If AWS creds missing: Configure ~/.aws/credentials"
echo "- If container not running: Run fix_deployment.sh"
echo "- If website not responding: Check docker logs"
echo ""
