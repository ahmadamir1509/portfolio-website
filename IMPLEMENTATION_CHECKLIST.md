# Implementation Checklist

## Pre-Deployment

- [ ] **Fork/Clone Repository** - Make sure you have the latest code locally
- [ ] **Review New Files:**
  - `.github/workflows/cicd.yml` - Updated workflow
  - `terraform/ecr.tf` - ECR configuration
  - `DOCKER_CICD_SUMMARY.md` - Overview
  - `DOCKER_CICD_SETUP.md` - Detailed guide
  - `ec2-docker-setup.sh` - EC2 setup script

## Step 1: GitHub Secrets Setup ⚙️

**Navigate to:** GitHub Repo → Settings → Secrets and variables → Actions → New repository secret

Add 3 secrets:

1. **Secret 1: AWS_ACCESS_KEY_ID**
   - Value: Your AWS access key
   - Click "Add secret"

2. **Secret 2: AWS_SECRET_ACCESS_KEY**
   - Value: Your AWS secret access key
   - Click "Add secret"

3. **Secret 3: EC2_SSH_PRIVATE_KEY**
   - Value: Content of your EC2 PEM file (github-deploy-pem.txt)
   - Click "Add secret"

**Verify:** You should see 3 secrets in the Actions section

## Step 2: EC2 Instance Preparation 🖥️

Connect to your EC2 instance:
```bash
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181
```

Run this command to setup Docker and AWS CLI:
```bash
# Copy and paste this entire block
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
aws --version
docker-compose --version
```

**Important:** Log out and log back in:
```bash
exit
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181
docker ps  # Should show empty table, not permission error
```

## Step 3: Deploy ECR with Terraform 🏗️

From your local machine:

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# When prompted: type 'yes'
```

**What gets created:**
- ECR Repository: `portfolio-website`
- Lifecycle policies
- Output: ECR repository URL

**Verify:**
```bash
aws ecr describe-repositories --region us-east-1
```

## Step 4: Initial Push to Trigger Pipeline 🚀

Make a simple change to your code and push:

```bash
# Make a small change
git add .
git commit -m "Enable Docker CI/CD pipeline"

# Push to main
git push origin main
```

**Monitor the deployment:**

1. Go to GitHub repo
2. Click **Actions** tab
3. You should see a new workflow run starting
4. Watch the 3 stages:
   - ✅ terraform-validate
   - ✅ build-and-push (builds Docker image and pushes to ECR)
   - ✅ deploy (deploys to EC2)

## Step 5: Verify Deployment ✅

### Option A: Check Website
```bash
curl http://98.93.75.181:5000/
# Should return HTML of your website
```

### Option B: SSH into EC2 and Check Container
```bash
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# See running containers
docker ps

# View logs
docker logs -f portfolio-website

# Check health
curl http://localhost:5000/
```

### Option C: Check ECR Images
```bash
aws ecr describe-images --repository-name portfolio-website --region us-east-1
```

## Step 6: Future Deployments 🔄

**From now on, every time you:**
1. Make changes to your code
2. Commit and push to `main` branch
3. GitHub Actions automatically:
   - Builds Docker image
   - Pushes to ECR
   - Deploys to EC2
   - Restarts the website

**No manual steps needed!**

## Troubleshooting 🔧

### Pipeline Fails at "Build and Push"
- [ ] Check GitHub Secrets are correctly set
- [ ] Verify AWS credentials have ECR permissions
- [ ] Check GitHub Actions logs for error message

### Deployment to EC2 Fails
- [ ] Verify EC2 has Docker installed: `docker --version`
- [ ] Verify AWS CLI installed: `aws --version`
- [ ] Check EC2 SSH connectivity: `ssh -i key.pem ec2-user@IP`
- [ ] Check logs on EC2: `docker logs portfolio-website`

### Website Not Responding
- [ ] Wait 10 seconds (container startup time)
- [ ] Refresh browser
- [ ] SSH to EC2 and run: `docker ps`
- [ ] Check container logs: `docker logs portfolio-website`
- [ ] Verify website locally: `curl http://localhost:5000/`

### ECR Not Accessible from EC2
- [ ] EC2 needs IAM role with ECR access
- [ ] Or configure AWS credentials on EC2: `aws configure`
- [ ] Test: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com`

## What's Different Now?

### Before (Manual):
1. Edit code locally
2. SSH into EC2
3. Git pull
4. Kill old process
5. Restart Flask
6. Hope nothing broke

### After (Automated):
1. Edit code locally
2. Push to GitHub
3. ✅ Automatic build, push, deploy
4. ✅ Old container stops gracefully
5. ✅ New container starts with health checks
6. ✅ Website updates within 2-3 minutes

## Quick Command Reference

```bash
# View workflow status
git log --oneline | head -5

# Check recent deployments
ssh -i key.pem ec2-user@IP "docker ps -a"

# View deployment logs
ssh -i key.pem ec2-user@IP "docker logs -f portfolio-website"

# Manual container restart (if needed)
ssh -i key.pem ec2-user@IP "docker restart portfolio-website"

# View ECR images
aws ecr describe-images --repository-name portfolio-website --region us-east-1

# See all deployments (GitHub)
git log --grep="Docker" --oneline
```

---

✅ **You're ready!** Follow the steps above in order and your automated CI/CD pipeline will be live!
