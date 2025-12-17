# Docker CI/CD Pipeline - Complete Setup Guide

## 📋 Summary of Changes

Your portfolio website now has a **fully automated Docker-based CI/CD pipeline** that:

✅ Builds Docker images automatically
✅ Pushes images to AWS ECR (Elastic Container Registry)
✅ Deploys containers to your EC2 instance
✅ Updates your website automatically on every GitHub push
✅ Includes health checks and auto-recovery

---

## 📁 Files Modified/Created

### Modified Files:
1. **`.github/workflows/cicd.yml`**
   - Complete rewrite with 3-stage pipeline
   - Terraform validation → Docker build & push → EC2 deployment

2. **`terraform/ecr.tf`**
   - Created ECR repository configuration
   - Added lifecycle policies for image management

### New Documentation Files:
1. **`DOCKER_CICD_SUMMARY.md`** - Quick overview
2. **`DOCKER_CICD_SETUP.md`** - Detailed setup guide
3. **`IMPLEMENTATION_CHECKLIST.md`** - Step-by-step checklist
4. **`ec2-docker-setup.sh`** - Automated EC2 setup script

---

## 🚀 3-Minute Setup

### 1. Add GitHub Secrets (2 min)
**GitHub → Settings → Secrets and variables → Actions → New secret**

```
AWS_ACCESS_KEY_ID = your_key
AWS_SECRET_ACCESS_KEY = your_secret
EC2_SSH_PRIVATE_KEY = (paste entire PEM file)
```

### 2. Setup EC2 Docker (1 min)
```bash
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Copy-paste the Docker setup commands from IMPLEMENTATION_CHECKLIST.md
```

### 3. Deploy ECR
```bash
cd terraform
terraform apply
# Type: yes
```

---

## 🔄 How It Works

```
Your Code Push to GitHub main branch
              ↓
    GitHub Actions Triggered
              ↓
1. Terraform Validate
         ✓ Pass
              ↓
2. Build Docker Image
    docker build ...
              ↓
3. Push to AWS ECR
    docker push to registry
              ↓
4. SSH into EC2
              ↓
5. EC2 Logs into ECR
    aws ecr get-login-password | docker login
              ↓
6. Pull Latest Image
    docker pull IMAGE_URI
              ↓
7. Stop Old Container
    docker stop portfolio-website
              ↓
8. Start New Container
    docker run -d portfolio-website
              ↓
9. Verify Website
    curl http://localhost:5000/
              ↓
✅ Website Updated Automatically!
```

---

## 📊 Pipeline Stages Explained

### Stage 1: Terraform Validation
- Validates your Terraform configuration
- Ensures ECR and infrastructure is correct
- **Runs:** Always
- **Duration:** ~30 seconds

### Stage 2: Build & Push to ECR
- Builds Docker image from your Dockerfile
- Logs into AWS ECR
- Pushes image with `latest` tag
- **Runs:** Only on push to `main` branch
- **Duration:** ~2-3 minutes
- **Output:** Image pushed to ECR registry

### Stage 3: Deploy to EC2
- SSHes into your EC2 instance
- EC2 logs into ECR
- Pulls the latest Docker image
- Stops old running container
- Starts new container with health checks
- Verifies website is responding
- **Runs:** Only on successful push to `main` branch
- **Duration:** ~1-2 minutes
- **Result:** Website updated!

---

## 🎯 Next Actions (In Order)

### Immediate (10 minutes)
- [ ] Review `IMPLEMENTATION_CHECKLIST.md`
- [ ] Add 3 GitHub Secrets
- [ ] SSH into EC2 and run Docker setup commands
- [ ] Deploy ECR with Terraform

### Next (5 minutes)
- [ ] Make a small code change
- [ ] Commit and push to `main`
- [ ] Watch GitHub Actions automatically deploy

### Verify (5 minutes)
- [ ] Go to GitHub → Actions → Watch deployment
- [ ] Visit http://98.93.75.181:5000 to verify
- [ ] Check EC2 for running container: `docker ps`

---

## 🔐 Security & Best Practices

✅ **Secrets:** GitHub Secrets encrypted, not in code
✅ **Credentials:** AWS credentials passed securely
✅ **Image Scanning:** ECR scans images for vulnerabilities
✅ **Health Checks:** Container health verified before completion
✅ **Auto-restart:** Container configured to restart on failure
✅ **Graceful Shutdown:** Old containers stopped cleanly

---

## 📈 Performance

**Deployment Time:** ~5-7 minutes total
- Validation: 30s
- Build & Push: 2-3 min
- Deploy to EC2: 1-2 min
- Startup time: 10-20s

**Website Downtime:** ~10-20 seconds during container restart

---

## 🛠️ Manual Operations

### View Deployment Logs (GitHub Actions)
1. Go to your GitHub repo
2. Click **Actions** tab
3. Click the latest workflow run
4. Expand each job to see logs

### Check Container Status (EC2)
```bash
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# See running containers
docker ps

# See all containers (including stopped)
docker ps -a

# View container logs
docker logs portfolio-website

# Follow logs in real-time
docker logs -f portfolio-website

# Check container health
docker inspect --format='{{json .State.Health}}' portfolio-website

# Manually restart container
docker restart portfolio-website
```

### Check ECR Images
```bash
aws ecr describe-images --repository-name portfolio-website --region us-east-1

# List all images with tags
aws ecr list-images --repository-name portfolio-website --region us-east-1
```

### Manual Deployment (if needed)
```bash
# SSH to EC2
ssh -i github-deploy-pem.txt ec2-user@98.93.75.181

# Get ECR login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Pull latest image
docker pull ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Stop and remove old container
docker stop portfolio-website
docker rm portfolio-website

# Start new container
docker run -d \
  --name portfolio-website \
  --restart always \
  -p 5000:5000 \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest
```

---

## ❌ Troubleshooting

### GitHub Actions Workflow Fails

**Problem:** Workflow shows red ✗
**Solution:**
- Go to Actions tab
- Click the failed workflow
- Expand each job to find error
- Common causes:
  - Missing GitHub Secrets
  - Wrong AWS credentials
  - Terraform validation error

**Check EC2 SSH Key:**
- Verify `EC2_SSH_PRIVATE_KEY` is full PEM file content
- Should start with `-----BEGIN RSA PRIVATE KEY-----`
- Should end with `-----END RSA PRIVATE KEY-----`

### ECR Login Fails on EC2

**Problem:** `docker pull` gives authentication error
**Solution:**
```bash
# Configure AWS credentials on EC2
aws configure
# Enter AWS_ACCESS_KEY_ID
# Enter AWS_SECRET_ACCESS_KEY
# Region: us-east-1
# Output: json

# Test login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### Container Won't Start

**Problem:** `docker ps` shows no container
**Solution:**
```bash
# Check logs
docker logs portfolio-website

# Check container status
docker inspect portfolio-website | grep State -A 10

# Try starting manually
docker run -d -p 5000:5000 ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/portfolio-website:latest

# Check if port is already in use
sudo netstat -tlnp | grep 5000
```

### Website Still Shows Old Content

**Problem:** You see old website version
**Solution:**
1. Hard refresh: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
2. Wait 20 seconds for container to fully start
3. Check deployment completed: GitHub Actions → Actions tab → look for ✅
4. Verify container running: `ssh ... docker ps | grep portfolio`
5. Check logs: `ssh ... docker logs portfolio-website`

### Build Fails: "Image already exists"

**Problem:** Docker build error
**Solution:**
- This is normal with continuous deployments
- GitHub Actions automatically handles this
- No action needed, will succeed on next push

---

## 📚 File References

For more detailed information, see:
- **`IMPLEMENTATION_CHECKLIST.md`** - Step-by-step setup guide
- **`DOCKER_CICD_SETUP.md`** - Detailed documentation
- **`.github/workflows/cicd.yml`** - The actual GitHub Actions workflow
- **`terraform/ecr.tf`** - ECR infrastructure code
- **`Dockerfile`** - Docker image configuration
- **`docker-compose.yml`** - Docker Compose reference (local testing)

---

## ✨ Key Features

| Feature | Benefit |
|---------|---------|
| **Automated Build** | No manual docker build commands |
| **Auto Push to ECR** | Centralized image registry |
| **Automated Deployment** | Website updates on every push |
| **Health Checks** | Container verified before considering success |
| **Auto-Restart** | Container restarts if it crashes |
| **Image Scanning** | Vulnerabilities detected automatically |
| **Image Cleanup** | Old images automatically removed |
| **Graceful Shutdown** | Old containers stop cleanly |
| **Terraform Validation** | Infrastructure checked before deployment |

---

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Documentation](https://docs.docker.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

---

## 📞 Support

If something doesn't work:

1. **Check GitHub Actions logs** for detailed error messages
2. **Check EC2 container logs**: `docker logs portfolio-website`
3. **Verify all GitHub Secrets** are correctly set
4. **Ensure EC2 has Docker installed**: `docker --version`
5. **Test SSH access to EC2**: `ssh -i key.pem ec2-user@IP`

---

## 🎉 You're All Set!

Once you complete the setup in `IMPLEMENTATION_CHECKLIST.md`, your website will automatically update whenever you:
1. Make changes to your code
2. Commit the changes
3. Push to `main` branch

**No manual deployment steps needed anymore!**

---

**Last Updated:** December 17, 2025
**Status:** Ready for deployment ✅
