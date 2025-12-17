# Docker CI/CD Deployment - Setup & Fix Guide

## Issue Found
✅ **FIXED**: Docker daemon was not running on EC2

## Current Status
- ✅ Docker installed on EC2 v25.0.13
- ✅ Docker daemon now running
- ✅ AWS CLI v2 installed on EC2
- ✅ GitHub Actions workflow configured with 3 stages
- ✅ ECR repository created (portfolio-website)
- ⚠️ **ISSUE**: AWS credentials not configured on EC2 for ECR access

## The Problem & Solution

### Why changes aren't appearing:
1. GitHub Actions builds Docker image ✅ (working)
2. Pushes to ECR ✅ (working)
3. **SSH to EC2 and tries to pull from ECR ❌ (fails - no AWS creds)**
4. Container doesn't get updated ❌
5. Old website keeps running ❌

### The Fix

#### Option 1: Attach IAM Role to EC2 (Recommended)
This is the **most secure** approach. The EC2 instance should have an IAM role with ECR access.

```bash
# On your local machine:
# 1. Go to AWS EC2 console
# 2. Select your instance (98.93.75.181)
# 3. Right-click → Instance Settings → Attach/Replace IAM Instance Profile
# 4. Select a role with ECR access (should exist from terraform)

# Then SSH and test:
ssh -i ec2-key-temp.pem ec2-user@98.93.75.181
aws sts get-caller-identity  # Should work without credentials
exit
```

#### Option 2: Configure AWS Credentials on EC2
If you don't have an IAM role, configure credentials manually:

```bash
ssh -i ec2-key-temp.pem ec2-user@98.93.75.181

# Create AWS credentials file
mkdir -p ~/.aws

cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_AWS_SECRET_KEY_HERE
EOF

# Create AWS config file
cat > ~/.aws/config << 'EOF'
[default]
region = us-east-1
output = json
EOF

chmod 600 ~/.aws/credentials ~/.aws/config

# Test it
aws sts get-caller-identity

exit
```

#### Option 3: Use the Fix Script (Quick Fix)
I've created `fix_deployment.sh` to automate the deployment:

```bash
# Upload and run the fix script
scp -i ec2-key-temp.pem fix_deployment.sh ec2-user@98.93.75.181:~/fix_deployment.sh
ssh -i ec2-key-temp.pem ec2-user@98.93.75.181 "chmod +x ~/fix_deployment.sh && ~/fix_deployment.sh"
```

---

## Step-by-Step: Complete Fix

### Step 1: Verify Docker is Running
```bash
ssh -i ec2-key-temp.pem ec2-user@98.93.75.181

# Check Docker daemon
sudo systemctl status docker

# If not running:
sudo systemctl start docker
```

### Step 2: Configure AWS Credentials
**IMPORTANT**: Get your AWS access key and secret key from:
- AWS Console → Security Credentials → Access Keys

Then run on EC2:
```bash
mkdir -p ~/.aws

cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG+PNEWcXAMPLEKEY
EOF

chmod 600 ~/.aws/credentials

# Verify
aws sts get-caller-identity
```

### Step 3: Test ECR Access
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 798541564412.dkr.ecr.us-east-1.amazonaws.com

# List images in ECR
aws ecr describe-images --repository-name portfolio-website --region us-east-1
```

### Step 4: Manual Deploy (Test)
```bash
# Pull latest image
IMAGE_URI="798541564412.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest"

# Login to ECR first
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 798541564412.dkr.ecr.us-east-1.amazonaws.com

# Pull and run
sudo docker pull $IMAGE_URI
sudo docker stop portfolio-website || true
sudo docker rm portfolio-website || true

sudo docker run -d \
  --name portfolio-website \
  --restart always \
  -p 5000:5000 \
  $IMAGE_URI

# Check it's running
sudo docker ps
sudo docker logs portfolio-website
```

### Step 5: Test Website
```bash
# On EC2
curl http://localhost:5000

# On your local machine (Windows):
# Open browser and go to: http://98.93.75.181:5000
```

---

## GitHub Actions Workflow - How It Works

Your workflow has 3 stages:

1. **Validate** (terraform-validate)
   - Checks Terraform code is valid
   - Runs on all pushes

2. **Build & Push** (build-and-push)
   - Runs only on `main` branch
   - Builds Docker image from your code
   - Pushes to ECR with `latest` tag
   - Returns image URI for deploy job

3. **Deploy** (deploy)
   - Runs only on `main` branch
   - Depends on build-and-push job
   - SSH to EC2
   - Uses AWS credentials passed from GitHub Secrets
   - Stops old container
   - Pulls new image from ECR
   - Starts new container with health checks
   - Verifies website responds

---

## Secrets Required in GitHub

Make sure these are set in your repository:

1. `AWS_ACCESS_KEY_ID` - Your AWS access key
2. `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
3. `EC2_SSH_PRIVATE_KEY` - Your EC2 PEM key (contents of ec2-key-temp.pem)

To add secrets:
- GitHub → Settings → Secrets and variables → Actions → New repository secret

---

## Testing the Full Workflow

Once everything is configured:

1. Make a small change to your code (e.g., add a comment)
2. Commit and push to main branch
3. Go to GitHub → Actions
4. Watch the workflow run through all 3 stages
5. Check website at http://98.93.75.181:5000 for the change

---

## Troubleshooting

### Docker daemon not running
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Auto-start on reboot
```

### Cannot connect to Docker daemon
```bash
# May need sudo
sudo docker ps

# Or add ec2-user to docker group
sudo usermod -aG docker ec2-user
# Then logout and login again
```

### ECR login fails
```bash
# Check credentials
aws sts get-caller-identity

# Check ECR repository exists
aws ecr describe-repositories --region us-east-1
```

### Container won't stay running
```bash
# Check logs
sudo docker logs portfolio-website

# Check if container keeps restarting
sudo docker ps -a

# Try running manually to see errors
sudo docker run -it --rm -p 5000:5000 798541564412.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest
```

---

## Quick Command Reference

```bash
# SSH to EC2
ssh -i ec2-key-temp.pem ec2-user@98.93.75.181

# View running containers
sudo docker ps

# View all containers (including stopped)
sudo docker ps -a

# View container logs
sudo docker logs portfolio-website

# Stop container
sudo docker stop portfolio-website

# Remove container
sudo docker rm portfolio-website

# View Docker images
sudo docker images

# Remove image
sudo docker rmi image-id

# Check AWS credentials
aws sts get-caller-identity

# Login to ECR
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 798541564412.dkr.ecr.us-east-1.amazonaws.com

# Pull image
sudo docker pull 798541564412.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Test website
curl http://localhost:5000
```

---

## Next Steps

1. **Fix AWS Credentials** (Pick Option 1, 2, or 3 above)
2. **Test Manual Deployment** (Step 4)
3. **Verify Website** (Step 5)
4. **Test GitHub Actions** (Push a test change)
5. **Celebrate!** 🎉

Once this is done, any changes you push to `main` branch will automatically:
- Build new Docker image with your changes
- Push to ECR
- Deploy to EC2
- Update the live website

---

## Still having issues?

Check these in order:

1. ✅ Docker running: `sudo systemctl status docker`
2. ✅ AWS credentials: `aws sts get-caller-identity`
3. ✅ ECR access: `aws ecr describe-repositories`
4. ✅ Image in ECR: `aws ecr describe-images --repository-name portfolio-website`
5. ✅ Website responding: `curl http://localhost:5000` (from EC2)
6. ✅ Container running: `sudo docker ps`
7. ✅ Container logs: `sudo docker logs portfolio-website`
