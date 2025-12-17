# Docker CI/CD Pipeline - Setup Summary

## ✅ Changes Made

### 1. **GitHub Actions Workflow** (`.github/workflows/cicd.yml`)
Updated with 3-stage Docker pipeline:
- **Terraform Validation**: Validates configuration
- **Build & Push to ECR**: Builds Docker image and pushes to AWS ECR
- **Deploy to EC2**: Pulls image, stops old container, runs new container

### 2. **ECR Terraform** (`terraform/ecr.tf`)
Created Elastic Container Registry with:
- Auto image scanning on push
- Lifecycle policy to keep last 5 images
- Automatic cleanup of old images

### 3. **Docker Image** (Already configured)
Your existing `Dockerfile` is optimized with:
- Multi-stage build (builder + runtime)
- Health checks
- Gunicorn WSGI server

## 🚀 Quick Start (4 Steps)

### Step 1: Add GitHub Secrets
Go to: **Settings → Secrets and variables → Actions** and add:

```
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
EC2_SSH_PRIVATE_KEY=
(paste entire PEM file content)
```

### Step 2: Setup EC2 Instance
SSH into your EC2 and run:
```bash
bash <(curl -s raw-github-url/ec2-docker-setup.sh)
```

Or manually:
```bash
sudo yum install -y docker
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker ec2-user
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip
```

### Step 3: Deploy ECR with Terraform
```bash
cd terraform
terraform init
terraform apply
```

### Step 4: Push to GitHub
Make any change to your code and push to `main`:
```bash
git add .
git commit -m "Enable Docker CI/CD"
git push origin main
```

## 📋 What Happens on Push

```
GitHub Push to main
    ↓
1️⃣ Terraform Validate
    ↓
2️⃣ Build Docker Image
    ↓
3️⃣ Push to AWS ECR
    ↓
4️⃣ SSH into EC2
    ↓
5️⃣ Pull Image from ECR
    ↓
6️⃣ Stop Old Container
    ↓
7️⃣ Start New Container
    ↓
8️⃣ Verify Website Running ✅
```

## 🔍 Monitoring

### Check Deployment Status
- Go to GitHub repo → **Actions** tab
- See detailed logs for each stage

### View EC2 Docker Logs
```bash
ssh -i your-key.pem ec2-user@98.93.75.181
docker logs -f portfolio-website
docker ps
```

### Check ECR Images
```bash
aws ecr describe-images --repository-name portfolio-website --region us-east-1
```

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| GitHub Actions fails | Check GitHub Secrets are set correctly |
| ECR login fails on EC2 | Verify AWS CLI installed and EC2 has IAM role |
| Container won't start | Check logs: `docker logs portfolio-website` |
| Website not responding | Wait 10 seconds, then refresh. Check health: `curl http://localhost:5000/` |

## 📁 Files Changed

- `.github/workflows/cicd.yml` - Complete workflow rewrite
- `terraform/ecr.tf` - ECR repository configuration
- `Dockerfile` - No changes (already optimized)
- `docker-compose.yml` - For local reference only

## ✨ Features

✅ Automatic deployment on GitHub push
✅ Docker containerization
✅ ECR image registry
✅ Health checks built-in
✅ Auto-rollback if container fails
✅ Image scanning
✅ Lifecycle policies (auto-cleanup old images)

## 📝 Next Actions

1. ✅ Review this file
2. ⏳ Add GitHub Secrets
3. ⏳ Run EC2 docker setup
4. ⏳ Deploy ECR with Terraform
5. ⏳ Push code change to trigger pipeline
6. ⏳ Monitor GitHub Actions
7. ⏳ Verify website at http://98.93.75.181:5000

## 💡 Now When You Make Changes

- Edit any file in your project
- Commit and push to `main` branch
- GitHub Actions automatically:
  1. Builds Docker image
  2. Pushes to ECR
  3. Deploys to EC2
- Website updates within 2-3 minutes
- No manual deployment needed!
