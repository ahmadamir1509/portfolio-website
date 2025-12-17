# Docker CI/CD Setup Guide

## Overview
This guide explains how to set up the automated Docker-based CI/CD pipeline that builds, pushes images to ECR, and deploys to EC2.

## Prerequisites

### 1. GitHub Secrets Setup
You need to add the following secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `EC2_SSH_PRIVATE_KEY`: Your EC2 PEM file content (copy entire content)

### 2. EC2 Instance Setup

Install Docker and AWS CLI on your EC2 instance:

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@98.93.75.181

# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Verify installations
docker --version
aws --version

# Log out and log back in to apply group changes
exit
ssh -i your-key.pem ec2-user@98.93.75.181
```

### 3. Terraform Setup

Deploy the ECR repository:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will create:
- ECR Repository: `portfolio-website`
- Lifecycle policies to manage image retention

### 4. How It Works

**Workflow Stages:**

1. **Terraform Validation** (terraform-validate)
   - Validates your Terraform configuration
   - Only proceeds if validation passes

2. **Build & Push to ECR** (build-and-push)
   - Builds Docker image from Dockerfile
   - Logs into AWS ECR
   - Pushes image with `latest` tag
   - Only runs on push to `main` branch

3. **Deploy to EC2** (deploy)
   - SSH into your EC2 instance
   - Logs into ECR on the EC2 machine
   - Stops and removes old container
   - Pulls the latest image from ECR
   - Starts new container with health checks
   - Verifies the website is running

## Automatic Deployment

**The pipeline runs automatically when you:**
- Push code to the `main` branch
- Changes detected in any file

**The pipeline does NOT run for:**
- Pull requests (only validates)
- Pushes to other branches

## Manual Testing

### Test locally with Docker:
```bash
# Build image
docker build -t portfolio-website:latest .

# Run container
docker run -d --name portfolio-test -p 5000:5000 portfolio-website:latest

# Test
curl http://localhost:5000/

# Stop container
docker stop portfolio-test
docker rm portfolio-test
```

### View logs from EC2:
```bash
ssh -i your-key.pem ec2-user@98.93.75.181
docker logs portfolio-website
docker ps
```

## Troubleshooting

### Check GitHub Actions Logs
Go to your GitHub repo → Actions tab → Click the workflow run to see logs

### Check EC2 Docker Logs
```bash
ssh -i your-key.pem ec2-user@98.93.75.181
docker logs portfolio-website
```

### Check ECR Images
```bash
aws ecr describe-images --repository-name portfolio-website --region us-east-1
```

### Redeploy manually
The workflow will run automatically on the next push to `main`

## Environment Variables

The container is configured with:
- `FLASK_ENV=production`
- `PORT=5000`

Modify in `.github/workflows/cicd.yml` if needed.

## Next Steps

1. Add GitHub secrets (AWS credentials and EC2 SSH key)
2. Run `terraform apply` to create ECR repository
3. Push a change to `main` branch to trigger the pipeline
4. Check GitHub Actions for deployment status
5. Visit http://98.93.75.181:5000 to verify
