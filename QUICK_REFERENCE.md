# Quick Visual Reference

## 🔄 The Complete Workflow

```
┌─────────────────────────────────────────────────────────┐
│              Your Local Machine                         │
│  1. Edit code in VS Code                                │
│  2. git add .                                           │
│  3. git commit -m "Updated website"                     │
│  4. git push origin main                                │
└─────────────────────────────────────────────────────────┘
                        ↓
                    GitHub gets push
                        ↓
        ┌───────────────────────────────────┐
        │  GitHub Actions Workflow Starts   │
        └───────────────────────────────────┘
                        ↓
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ JOB 1: Terraform Validate    ┃
        ┃ - terraform init             ┃
        ┃ - terraform validate         ┃
        ┃ ✅ PASS → Continue           ┃
        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                        ↓
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ JOB 2: Build & Push to ECR   ┃
        ┃ - docker build .              ┃
        ┃ - docker login to ECR         ┃
        ┃ - docker push to ECR          ┃
        ┃ ✅ Image in registry           ┃
        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                        ↓
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ JOB 3: Deploy to EC2         ┃
        ┃ - SSH into EC2                ┃
        ┃ - docker login to ECR         ┃
        ┃ - docker pull latest image    ┃
        ┃ - docker stop old container   ┃
        ┃ - docker run new container    ┃
        ┃ - verify website online       ┃
        ┃ ✅ Website Updated!            ┃
        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                        ↓
┌─────────────────────────────────────────────────────────┐
│              Your EC2 Instance                          │
│  🐳 New container running your latest code              │
│  Website updated and ready to serve                     │
│  http://98.93.75.181:5000                               │
└─────────────────────────────────────────────────────────┘
```

## 📊 Execution Flow

```
PUSH TO MAIN
    ↓
[✓ Git validated]
    ↓
[✓ Terraform validated]
    ↓
[✓ Docker built]
    ↓
[✓ Image pushed to ECR]
    ↓
[✓ EC2 logged into ECR]
    ↓
[✓ Image pulled to EC2]
    ↓
[✓ Old container stopped]
    ↓
[✓ New container started]
    ↓
[✓ Health check passed]
    ↓
[✓ Website responding]
    ↓
✅ DEPLOYMENT COMPLETE
   Website now running new code!
```

## 🎯 Setup Sequence

```
STEP 1: GitHub Secrets
┌──────────────────────────────────────┐
│ GitHub Repo Settings                 │
│ → Secrets and variables              │
│ → Add 3 secrets:                     │
│   1. AWS_ACCESS_KEY_ID               │
│   2. AWS_SECRET_ACCESS_KEY           │
│   3. EC2_SSH_PRIVATE_KEY             │
└──────────────────────────────────────┘
        ↓ STEP 2: EC2 Setup
┌──────────────────────────────────────┐
│ SSH into EC2                         │
│ Run Docker + AWS CLI installation    │
│ Verify: docker ps, aws --version     │
└──────────────────────────────────────┘
        ↓ STEP 3: Terraform
┌──────────────────────────────────────┐
│ cd terraform                         │
│ terraform init                       │
│ terraform apply                      │
│ Creates ECR repository               │
└──────────────────────────────────────┘
        ↓ STEP 4: First Push
┌──────────────────────────────────────┐
│ git add .                            │
│ git commit -m "Enable Docker CI/CD" │
│ git push origin main                 │
│ Watch GitHub Actions                 │
└──────────────────────────────────────┘
        ↓ DONE!
┌──────────────────────────────────────┐
│ Website auto-updates on every push! │
│ No manual deployment needed!         │
└──────────────────────────────────────┘
```

## 📁 Project Structure

```
Portfolio_devops/
├── .github/
│   └── workflows/
│       └── cicd.yml              ← Updated with Docker steps
│
├── terraform/
│   ├── ecr.tf                    ← NEW: ECR configuration
│   ├── ec2.tf
│   ├── security_groups.tf
│   └── ... other tf files
│
├── app.py                        ← Flask application
├── Dockerfile                    ← Docker image definition
├── docker-compose.yml            ← For local testing
├── requirements.txt              ← Python dependencies
│
├── DOCKER_CICD_README.md         ← Overview (THIS FILE)
├── DOCKER_CICD_SETUP.md          ← Detailed guide
├── DOCKER_CICD_SUMMARY.md        ← Quick reference
├── IMPLEMENTATION_CHECKLIST.md   ← Step-by-step setup
│
└── ... other files
```

## ⏱️ Timeline

```
Local Development (You)
    0 min: Edit code
    1 min: git push origin main
              ↓
    2 min: GitHub Actions starts
              ↓
    3 min: Terraform validation ✅
              ↓
    5 min: Docker build complete ✅
              ↓
    6 min: Image pushed to ECR ✅
              ↓
    7 min: EC2 deployment starts
              ↓
    8 min: Container running ✅
              ↓
   ==============================
   TOTAL TIME: ~6-8 minutes
   WEBSITE UPDATED!
```

## 🔐 Security Flow

```
┌─ Your Machine ─────────┐
│ git push to main       │  (Public repo)
└────────────────────────┘
           ↓ (GitHub Actions sees push)
┌─ GitHub Actions ───────────────────────┐
│ Read: GitHub Secrets (encrypted)       │
│  → AWS_ACCESS_KEY_ID                   │
│  → AWS_SECRET_ACCESS_KEY               │
│  → EC2_SSH_PRIVATE_KEY                 │
│ Use: To authenticate to AWS and EC2    │
└────────────────────────────────────────┘
           ↓ (Secrets never logged/exposed)
┌─ AWS ECR ──────────────┐
│ Authenticate           │
│ Push Docker image      │
└────────────────────────┘
           ↓
┌─ EC2 Instance ─────────┐
│ Pull image from ECR    │
│ Run container          │
└────────────────────────┘
```

## 🔍 Monitoring Checklist

```
✓ GitHub Actions Log
  Settings → Actions → [Workflow name] → Logs
  
✓ EC2 Container Logs
  ssh ... ec2-user@IP "docker logs portfolio-website"
  
✓ Container Running
  ssh ... ec2-user@IP "docker ps"
  
✓ Website Responding
  curl http://98.93.75.181:5000/
  
✓ ECR Images
  aws ecr describe-images --repository-name portfolio-website
  
✓ Container Health
  ssh ... ec2-user@IP "docker inspect portfolio-website | grep -A 10 Health"
```

## 🚀 Usage Commands

```
# Push changes to trigger deployment
git add .
git commit -m "Your changes"
git push origin main

# Monitor in GitHub
GitHub → Actions → Watch the workflow run

# Check EC2 status
ssh -i key.pem ec2-user@IP "docker ps"

# View logs
ssh -i key.pem ec2-user@IP "docker logs -f portfolio-website"

# Manual restart (if needed)
ssh -i key.pem ec2-user@IP "docker restart portfolio-website"

# Check ECR images
aws ecr describe-images --repository-name portfolio-website --region us-east-1
```

## 📈 Metrics

```
Build Time:        ~2-3 minutes
Deployment Time:   ~1-2 minutes  
Container Start:   ~10-20 seconds
Total Time:        ~5-7 minutes

Website Downtime:  ~10-20 seconds (during container switch)

ECR Storage:       Lifecycle policy keeps last 5 images
EC2 Storage:       Only 1 container running at a time
```

## ✅ Success Indicators

```
✅ Terraform Validation PASSED
   → Infrastructure is correct

✅ Build & Push PASSED
   → Docker image created and in ECR

✅ Deploy to EC2 PASSED
   → Container running on EC2

✅ Verify Website PASSED
   → Website responding at http://98.93.75.181:5000

✅ All Stages Green
   → Deployment complete!

🌐 Visit website → See your latest changes!
```

## ⚠️ Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| GitHub Actions shows ✗ | Check GitHub Secrets are set |
| ECR login fails | Verify AWS credentials on EC2 |
| Container won't start | Check Docker logs: `docker logs portfolio-website` |
| Old website still showing | Hard refresh: Ctrl+Shift+R or wait 20 seconds |
| Permission denied SSH | Verify PEM file permissions: `chmod 600 key.pem` |
| Port already in use | `ssh ... "docker stop portfolio-website"` |

---

## 🎓 Key Concepts

- **GitHub Actions**: Automated workflow on every push
- **Docker**: Container with your application
- **ECR**: AWS registry to store Docker images
- **EC2**: Server running your container
- **CI/CD**: Continuous Integration / Continuous Deployment

---

## 📞 Quick Reference

```
Website URL:          http://98.93.75.181:5000
GitHub Actions:       GitHub Repo → Actions tab
EC2 SSH:             ssh -i github-deploy-pem.txt ec2-user@98.93.75.181
Docker Command:      docker ps, docker logs, docker restart
AWS ECR Console:     https://console.aws.amazon.com/ecr/
```

---

**Remember:** Every push to `main` = automatic deployment!
