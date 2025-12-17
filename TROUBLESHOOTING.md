# Docker CI/CD - Command Reference & Troubleshooting

## 🔧 Essential Commands

### GitHub Actions Monitoring

```bash
# View workflow in GitHub
# 1. Go to https://github.com/[your-repo]/actions
# 2. Click the workflow run to see detailed logs
# 3. Expand each job to see step-by-step execution

# Watch real-time:
# Go to Actions tab and refresh frequently during deployment
```

### EC2 Docker Commands

```bash
# SSH into EC2
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs portfolio-website

# Follow logs in real-time (press Ctrl+C to exit)
docker logs -f portfolio-website

# See last 100 lines
docker logs --tail 100 portfolio-website

# See logs since last 5 minutes
docker logs --since 5m portfolio-website

# Get detailed container info
docker inspect portfolio-website

# Check container health status
docker inspect --format='{{json .State.Health}}' portfolio-website | jq

# View container resource usage
docker stats portfolio-website

# List all images
docker images

# Remove a container
docker stop portfolio-website && docker rm portfolio-website

# Restart container
docker restart portfolio-website

# See running processes in container
docker top portfolio-website

# Connect to running container
docker exec -it portfolio-website bash

# Test website from EC2
curl -v http://localhost:5000/

# See port bindings
docker port portfolio-website

# View container events
docker events --filter container=portfolio-website
```

### AWS ECR Commands

```bash
# List all ECR repositories
aws ecr describe-repositories --region us-east-1

# List images in repository
aws ecr list-images --repository-name portfolio-website --region us-east-1

# Get image details
aws ecr describe-images --repository-name portfolio-website --region us-east-1

# Get ECR login token (valid for 12 hours)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Manually push image (advanced)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Get ECR repository URL
aws ecr describe-repositories --repository-names portfolio-website --region us-east-1 --query 'repositories[0].repositoryUri' --output text

# Scan image for vulnerabilities
aws ecr start-image-scan --repository-name portfolio-website --image-id imageTag=latest --region us-east-1

# Get scan results
aws ecr describe-image-scan-findings --repository-name portfolio-website --image-id imageTag=latest --region us-east-1
```

### Terraform Commands

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (first time only)
terraform init

# Validate configuration
terraform validate

# Plan deployment (see what will be created)
terraform plan

# Apply changes (creates resources)
terraform apply

# See all resources created
terraform state list

# Destroy resources (removes ECR)
terraform destroy

# Get outputs (ECR URL, etc)
terraform output

# Specific output
terraform output ecr_repository_url
```

### Git Commands

```bash
# See recent commits
git log --oneline | head -5

# See changes made
git diff

# See changes staged
git diff --staged

# Check branch
git branch

# Switch to main
git checkout main

# Pull latest
git pull origin main

# Push to main
git push origin main

# View commit history
git log --graph --oneline --all
```

---

## ❌ Troubleshooting Guide

### Issue 1: GitHub Actions Workflow Fails Immediately

**Symptoms:**
- Red ✗ on workflow
- Shows error in first few seconds

**Solutions:**

```bash
# Check GitHub Secrets are set correctly
# Go to: GitHub → Settings → Secrets → Verify all 3 exist:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY  
# - EC2_SSH_PRIVATE_KEY

# Check GitHub Actions logs
# Click the failed workflow → Expand each job → Read error message

# Common errors:
# "No secrets found" → Add secrets above
# "terraform not found" → Actions runner issue, try re-running
# "invalid request" → Check secret format
```

### Issue 2: "Failed to Build Docker Image"

**Symptoms:**
- Build step fails
- Error mentions Dockerfile

**Solutions:**

```bash
# Test Dockerfile locally first
docker build -t portfolio-test .

# Check Dockerfile syntax
cat Dockerfile | head -20

# Verify all files exist
ls -la app.py requirements.txt Dockerfile
ls -la templates/ static/

# Check Docker daemon running locally
docker ps

# If all OK, check GitHub Actions logs for specific error message
# Common issues:
# - Missing files (app.py, requirements.txt)
# - Syntax error in Dockerfile
# - Port already in use
```

### Issue 3: ECR Push Fails - "Unauthorized"

**Symptoms:**
- Error: "unauthorized: authentication required"
- Build step shows ECR authentication failed

**Solutions:**

```bash
# Check AWS credentials in GitHub
# Verify AWS_ACCESS_KEY_ID has ECR permissions

# Test AWS credentials manually
aws ecr describe-repositories --region us-east-1

# If fails, update credentials:
# 1. Go to GitHub Secrets
# 2. Update AWS_ACCESS_KEY_ID
# 3. Update AWS_SECRET_ACCESS_KEY
# 4. Re-run workflow

# Verify AWS user has ECR permissions:
# AWS Console → IAM → Users → Check permissions
```

### Issue 4: SSH to EC2 Fails - "Permission Denied"

**Symptoms:**
- GitHub Actions fails at SSH step
- Error: "permission denied (publickey)"

**Solutions:**

```bash
# Verify EC2_SSH_PRIVATE_KEY in GitHub
# Should be complete PEM file content:
# -----BEGIN RSA PRIVATE KEY-----
# [lots of characters]
# -----END RSA PRIVATE KEY-----

# Test SSH locally
ssh -i github-deploy-pem.txt -v ec2-user@98.93.75.181

# If verbose output shows auth errors:
# 1. Verify PEM file permissions: chmod 600 github-deploy-pem.txt
# 2. Verify using right username: ec2-user (not ubuntu, not root)
# 3. Verify security group allows SSH (port 22)

# Check EC2 security group (AWS Console):
# EC2 → Security Groups → Inbound Rules
# Should have: SSH (22) open to your IP
```

### Issue 5: Container Fails to Start

**Symptoms:**
- Docker logs show errors
- `docker ps` shows no container
- Website not responding

**Solutions:**

```bash
# SSH to EC2
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Check if Docker is running
docker ps

# If Docker command fails, Docker not running:
sudo systemctl start docker

# View failed container logs
docker logs portfolio-website

# Common errors in logs:
# "port 5000 already in use" → Kill old process
#   sudo lsof -i :5000
#   kill -9 [PID]
#   docker start portfolio-website

# "image not found" → Image not pulled correctly
#   docker pull ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest
#   docker run -d -p 5000:5000 ...

# "flask app not starting" → App error
#   Check requirements.txt has all dependencies
#   Check app.py has no syntax errors
```

### Issue 6: ECR Login Fails on EC2 - "Access Denied"

**Symptoms:**
- GitHub Actions deployment fails
- Error: "no basic auth credentials" or "access denied"

**Solutions:**

```bash
# SSH to EC2
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Test AWS CLI
aws sts get-caller-identity

# If fails: AWS credentials not configured
# Option 1: Configure AWS CLI
aws configure
# Enter: AWS_ACCESS_KEY_ID
# Enter: AWS_SECRET_ACCESS_KEY
# Region: us-east-1
# Output: json

# Option 2: Use EC2 IAM role (recommended for production)
# AWS Console → EC2 → Instance Details → IAM role
# Should have policy allowing ECR access

# Test ECR login manually
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# If this works, GitHub Actions should work too
# Re-run the workflow from GitHub
```

### Issue 7: Website Still Shows Old Content

**Symptoms:**
- GitHub Actions shows ✅ (success)
- But website hasn't updated

**Solutions:**

```bash
# Hard refresh browser
# Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

# Wait for container startup
# Takes ~10-20 seconds for Flask to fully start
# Try again in 30 seconds

# SSH to EC2 and verify new container running
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181
docker ps

# Check container creation time (should be recent)
# If old, the new one didn't start:
docker logs portfolio-website

# Check if port is correct
curl -v http://localhost:5000/

# Check GitHub Actions actually deployed
# Go to Actions tab → Check latest workflow is ✅
# Check "Deploy" job completed successfully
```

### Issue 8: Deployment Takes Too Long

**Symptoms:**
- Workflow running for >10 minutes
- Waiting at certain step

**Solutions:**

```bash
# Normal timing:
# Terraform: 30-60 seconds
# Build: 2-3 minutes
# Push to ECR: 30-60 seconds
# Deploy to EC2: 1-2 minutes
# Total: 5-7 minutes

# If stuck at Build step:
# Likely downloading Python dependencies
# This can take 2-3 minutes depending on network
# Check if workflow is still running: Actions tab

# If stuck at SSH step:
# Possible network issue with EC2
# Check EC2 is running: AWS Console → EC2 → Instances

# If stuck at container startup:
# Normal if first time (downloads base image)
# Takes ~20-30 seconds normally
# If >2 minutes, something wrong with Flask app
```

### Issue 9: Terraform Apply Fails

**Symptoms:**
- Error running `terraform apply`
- ECR not created

**Solutions:**

```bash
# Run terraform validate first
cd terraform
terraform validate

# If error, shows what's wrong
# Common issues:
# - Invalid resource definition
# - Wrong syntax

# View terraform.tfstate for debug info
# Run plan first to see what will happen
terraform plan

# If plan works but apply fails, try again:
terraform apply

# If still fails, check AWS credentials:
aws sts get-caller-identity

# Check AWS account has ECR permission:
# AWS Console → IAM → Your User → Permissions
# Should have policy: AmazonEC2ContainerRegistryPowerUser
```

### Issue 10: Multiple Containers Running

**Symptoms:**
- `docker ps` shows multiple portfolio-website containers
- Website behaving strangely

**Solutions:**

```bash
# SSH to EC2
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# List all containers
docker ps -a | grep portfolio

# Stop all old containers
docker stop $(docker ps -a -q -f "name=portfolio-website")

# Remove all old containers  
docker rm $(docker ps -a -q -f "name=portfolio-website")

# Verify only one left
docker ps

# Start fresh deployment (push to GitHub)
```

---

## 🔍 Diagnostic Commands

```bash
# Full system health check
echo "=== Docker Status ===" && docker ps
echo "=== Container Logs ===" && docker logs --tail 50 portfolio-website
echo "=== Container Health ===" && docker inspect portfolio-website | grep -A 5 Health
echo "=== Port Binding ===" && docker port portfolio-website
echo "=== Website Response ===" && curl -w "\nStatus: %{http_code}\n" http://localhost:5000/
echo "=== AWS Credentials ===" && aws sts get-caller-identity
echo "=== ECR Access ===" && aws ecr describe-repositories --region us-east-1 --query 'repositories[0].repositoryName' --output text
```

## 📋 Pre-Deployment Checklist

```bash
# Run on EC2 before first deployment:

# Check Docker installed
[ -x "$(command -v docker)" ] && echo "✓ Docker installed" || echo "✗ Docker missing"

# Check Docker running
docker ps > /dev/null && echo "✓ Docker running" || echo "✗ Docker not running"

# Check AWS CLI installed
[ -x "$(command -v aws)" ] && echo "✓ AWS CLI installed" || echo "✗ AWS CLI missing"

# Check AWS credentials
aws sts get-caller-identity && echo "✓ AWS credentials valid" || echo "✗ AWS credentials invalid"

# Check ECR access
aws ecr describe-repositories --region us-east-1 && echo "✓ ECR accessible" || echo "✗ ECR not accessible"

# Check port 5000 available
! sudo lsof -i :5000 && echo "✓ Port 5000 free" || echo "✗ Port 5000 in use"
```

---

## 🚀 Recovery Procedures

### Full Redeployment

```bash
# If everything fails, manual redeployment:
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Stop everything
docker stop portfolio-website 2>/dev/null || true
docker rm portfolio-website 2>/dev/null || true

# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Pull latest image
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
docker pull $ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Run container
docker run -d \
  --name portfolio-website \
  --restart always \
  -p 5000:5000 \
  -e FLASK_ENV=production \
  $ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Verify
sleep 5
curl http://localhost:5000/
```

### Reset Everything

```bash
# WARNING: Removes all containers and resets
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Remove all containers
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -a -q) 2>/dev/null || true

# Remove all images
docker rmi $(docker images -q) 2>/dev/null || true

# Restart Docker daemon
sudo systemctl restart docker

# Verify clean
docker ps
docker images
```

---

**Last Updated:** December 17, 2025
**For issues:** Check GitHub Actions logs first, then EC2 Docker logs
