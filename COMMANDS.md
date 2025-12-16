# Complete Step-by-Step Commands - S3 Static Website Deployment

Copy and paste each command section into your terminal in order.

---

## PHASE 1: AWS Setup

### Step 1.1: Set Environment Variables (PowerShell)

```powershell
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCOUNT_ID = "YOUR_AWS_ACCOUNT_ID"
$env:GITHUB_USERNAME = "YOUR_GITHUB_USERNAME"
$env:BUCKET_NAME = "your-portfolio-website"

# Verify AWS CLI
aws sts get-caller-identity
```

### Step 1.2: Set Up OIDC Provider

```powershell
# Create OIDC provider
aws iam create-open-id-connect-provider `
  --url https://token.actions.githubusercontent.com `
  --client-id-list sts.amazonaws.com `
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 `
  2>$null

# Get Account ID
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
Write-Host "Your AWS Account ID: $ACCOUNT_ID"
```

### Step 1.3: Create Trust Policy

```powershell
$TrustPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{
                Federated = "arn:aws:iam::$($ACCOUNT_ID):oidc-provider/token.actions.githubusercontent.com"
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = @{
                StringEquals = @{
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                }
                StringLike = @{
                    "token.actions.githubusercontent.com:sub" = "repo:$($env:GITHUB_USERNAME)/portfolio-website:*"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$TrustPolicy | Out-File -Encoding UTF8 trust-policy.json
```

### Step 1.4: Create GitHub Actions Role

```powershell
# Create role
aws iam create-role `
  --role-name GitHubActionsRole `
  --assume-role-policy-document file://trust-policy.json

# Create inline policy
$Policy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @(
                "s3:*"
            )
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

$Policy | Out-File -Encoding UTF8 github-actions-policy.json

aws iam put-role-policy `
  --role-name GitHubActionsRole `
  --policy-name GitHubActionsPolicy `
  --policy-document file://github-actions-policy.json

# Get and save the role ARN
$ROLE_ARN = aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
Write-Host "GitHub Actions Role ARN: $ROLE_ARN"
Write-Host "Save this for GitHub Secrets!"
```

---

## PHASE 2: GitHub Configuration

### Step 2.1: Add GitHub Secrets

1. Go to: **GitHub Repository → Settings → Secrets and variables → Actions**
2. Click **"New repository secret"**
3. Add secret:
   - **Name**: `AWS_ROLE_ARN`
   - **Value**: (copy the ARN from Step 1.4 output)

---

## PHASE 3: Deploy with Terraform

### Step 3.1: Initialize Terraform

```powershell
cd c:\Users\Devops\Portfolio_website\Portfolio_devops\terraform

terraform init -backend=false

terraform validate
```

### Step 3.2: Plan Infrastructure

```powershell
terraform plan `
  -var="bucket_name=noor-portfolio-website" `
  -var="aws_region=us-east-1"
```

### Step 3.3: Apply Infrastructure

```powershell
terraform apply -auto-approve `
  -var="bucket_name=noor-portfolio-website" `
  -var="aws_region=us-east-1"
```

### Step 3.4: Get S3 Bucket URL

```powershell
terraform output website_domain
```

Save this URL - it's your website!

---

## PHASE 4: Prepare and Push Code

### Step 4.1: Initialize Git Repository

```powershell
cd c:\Users\Devops\Portfolio_website\Portfolio_devops

git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

git init
```

### Step 4.2: Add GitHub Remote

```powershell
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/portfolio-website.git
```

### Step 4.3: Commit and Push Code

```powershell
git add .

git commit -m "Initial commit: Static website with Terraform and GitHub Actions CI/CD"

git branch -M main

git push -u origin main
```

**This triggers the GitHub Actions pipeline!**

---

## PHASE 5: Monitor Deployment

### Step 5.1: View GitHub Actions

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click on the running workflow
4. Watch jobs execute:
   - ✅ **terraform-validate**: Validates code
   - ✅ **deploy**: Deploys to S3

### Step 5.2: Check Deployment Status

```powershell
# Get the website URL
cd terraform
terraform output website_domain

# Example output: http://noor-portfolio-website.s3-website-us-east-1.amazonaws.com
```

### Step 5.3: Test Your Website

```powershell
# Open in browser (replace with your URL)
$WEBSITE_URL = (cd terraform; terraform output -raw website_domain)
Start-Process $WEBSITE_URL
```

---

## PHASE 6: Update Website

Make changes and auto-deploy:

### Step 6.1: Edit Website Files

```powershell
# Edit index.html or add new HTML files
# Use your editor to make changes
```

### Step 6.2: Push Changes

```powershell
git add .
git commit -m "Update website content"
git push origin main
```

GitHub Actions automatically:
- ✅ Validates Terraform
- ✅ Deploys HTML/CSS to S3
- ✅ Website updates instantly

---

## Complete Pipeline Flow

```
┌──────────────────────┐
│   Make Changes       │
│   Edit index.html    │
└──────────────┬───────┘
               │
               ▼
┌──────────────────────┐
│   git push origin    │
│        main          │
└──────────────┬───────┘
               │
               ▼
┌──────────────────────────────┐
│   GitHub Actions Triggers    │
└──────────────┬───────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌──────────────┐  ┌──────────────┐
│  Terraform   │  │   Upload     │
│  Validates   │  │   HTML to S3 │
└──────────────┘  └──────────────┘
        │             │
        └──────┬──────┘
               ▼
        ┌─────────────┐
        │ Website     │
        │ Live! 🎉    │
        └─────────────┘
```

---

## Files Deployed

- `index.html` - Homepage
- `error.html` - Error page
- `static/css/styles.css` - Stylesheets (if exists)
- Any other `.html`, `.css`, `.js` files in root

---

## Useful Commands

```powershell
# Get website URL
cd terraform
terraform output website_domain

# Get bucket name
terraform output bucket_name

# Destroy everything
terraform destroy -auto-approve `
  -var="bucket_name=noor-portfolio-website" `
  -var="aws_region=us-east-1"

# Check git status
git status

# View commit history
git log --oneline

# Delete a file and push
git rm filename.html
git commit -m "Delete filename"
git push origin main
```

---

## Troubleshooting

**GitHub Actions fails with "Access Denied":**
- Verify AWS_ROLE_ARN secret is exactly correct
- Check OIDC provider exists

**404 error on website:**
- Verify bucket name matches in Terraform
- Check index.html exists in repo root

**Website returns 403 Forbidden:**
- Run terraform apply again to update bucket policy
- Wait 1-2 minutes for S3 to sync

**Can't push to GitHub:**
```powershell
# Check remote URL
git remote -v

# Update if needed
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/portfolio-website.git
```

---

## Summary

✅ All AWS resources created  
✅ GitHub Actions configured  
✅ Terraform managing S3  
✅ Website deployed and live  
✅ Auto-deployment on git push  

**Your static website is live and auto-deploying!** 🚀


### Step 1.1: Set Environment Variables

```powershell
# PowerShell (for Windows users)
$env:AWS_REGION = "us-east-1"
$env:AWS_ACCOUNT_ID = "(Get from AWS Console: Account ID)"
$env:GITHUB_USERNAME = "YOUR_GITHUB_USERNAME"
$env:REPO_NAME = "portfolio-website"

# Verify AWS CLI is configured
aws sts get-caller-identity
```

### Step 1.2: Create SSH Key Pair for EC2

```powershell
# Create SSH key (run this once)
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\portfolio-website" -N ""

# Import public key to AWS
$PublicKey = Get-Content "$env:USERPROFILE\.ssh\portfolio-website.pub" | Select-Object -First 1
aws ec2 import-key-pair `
  --key-name portfolio-website-key `
  --public-key-material $PublicKey `
  --region us-east-1

# Get private key in base64 (you'll need this for GitHub secrets)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$env:USERPROFILE\.ssh\portfolio-website")) | Out-File -NoNewline private-key-base64.txt
```

### Step 1.3: Set Up OIDC Provider (GitHub ↔ AWS Trust)

```powershell
# Create OIDC provider
aws iam create-open-id-connect-provider `
  --url https://token.actions.githubusercontent.com `
  --client-id-list sts.amazonaws.com `
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 `
  2>$null

# Get your AWS Account ID
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
Write-Host "Your AWS Account ID: $ACCOUNT_ID"
```

### Step 1.4: Create IAM Role for GitHub Actions

```powershell
# Create trust policy
$TrustPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{
                Federated = "arn:aws:iam::$($ACCOUNT_ID):oidc-provider/token.actions.githubusercontent.com"
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = @{
                StringEquals = @{
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                }
                StringLike = @{
                    "token.actions.githubusercontent.com:sub" = "repo:$($env:GITHUB_USERNAME)/$($env:REPO_NAME):*"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$TrustPolicy | Out-File -Encoding UTF8 trust-policy.json

# Create IAM role
aws iam create-role `
  --role-name GitHubActionsRole `
  --assume-role-policy-document file://trust-policy.json

# Create inline policy
$Policy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @(
                "ecr:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "iam:PassRole",
                "logs:*",
                "s3:*",
                "dynamodb:*"
            )
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

$Policy | Out-File -Encoding UTF8 github-actions-policy.json

aws iam put-role-policy `
  --role-name GitHubActionsRole `
  --policy-name GitHubActionsPolicy `
  --policy-document file://github-actions-policy.json

# Get the role ARN (save this!)
$ROLE_ARN = aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
Write-Host "GitHub Actions Role ARN: $ROLE_ARN"
```

---

## PHASE 2: GitHub Setup

### Step 2.1: Add Secrets to GitHub Repository

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Click **"New repository secret"** and add:

1. **AWS_ROLE_ARN**
   - Value: (from Step 1.6 output: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole)

2. **EC2_SSH_PRIVATE_KEY**
   - Value: (content of private-key-base64.txt from Step 1.4)

---

## PHASE 3: Deploy Infrastructure with Terraform

### Step 3.1: Initialize Terraform

```powershell
cd terraform

# Initialize backend
terraform init

# Validate configuration
terraform validate
```

### Step 3.2: Plan Infrastructure

```powershell
# Create execution plan
terraform plan -out=tfplan -var="aws_region=us-east-1" -var="instance_type=t2.micro" -var="environment=production"
```

### Step 3.3: Apply Infrastructure

```powershell
# Deploy everything
terraform apply tfplan

# Get outputs
terraform output -json | Out-File outputs.json
```

**This creates:**
- ✅ VPC with public subnets
- ✅ Security groups
- ✅ ECR repository
- ✅ EC2 instance
- ✅ Application Load Balancer
- ✅ IAM roles

---

## PHASE 4: Prepare Local Repository

### Step 4.1: Initialize Git

```powershell
cd c:\Users\Devops\Portfolio_website\Portfolio_devops

# Set git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Initialize git
git init

# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/$env:GITHUB_USERNAME/portfolio-website.git
```

### Step 4.2: Commit All Files

```powershell
# Stage all files
git add .

# Create commit
git commit -m "Initial commit: Complete CI/CD pipeline with Docker, Terraform, GitHub Actions"

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub (this TRIGGERS the pipeline!)
git push -u origin main
```

---

## PHASE 5: Test Locally (Before Pipeline)

### Step 5.1: Build Docker Image

```powershell
cd c:\Users\Devops\Portfolio_website\Portfolio_devops

docker build -t portfolio-website:latest .
```

### Step 5.2: Run Container Locally

```powershell
docker run -d `
  --name portfolio-website-test `
  -p 5000:5000 `
  -e FLASK_ENV=production `
  portfolio-website:latest

# Wait 5 seconds for app to start
Start-Sleep -Seconds 5

# Test application
curl http://localhost:5000

# Clean up
docker stop portfolio-website-test
docker rm portfolio-website-test
```

### Step 5.3: Test with Docker Compose

```powershell
# Start services
docker-compose up -d

# Check logs
docker-compose logs -f

# Access application
curl http://localhost:5000

# Stop services
docker-compose down
```

---

## PHASE 6: Monitor Pipeline Execution

### Step 6.1: View GitHub Actions

1. Go to your GitHub repository
2. Click "**Actions**" tab
3. Click on latest workflow run
4. Watch jobs execute:
   - ✅ **terraform-validate**: Validates infrastructure code
   - ✅ **build-and-push**: Builds Docker image and pushes to ECR
   - ✅ **deploy-to-ec2**: Deploys to EC2 instance

### Step 6.2: Check Pipeline Status

```powershell
# Monitor CloudWatch logs
aws logs tail /aws/ec2/portfolio-website --follow

# Check EC2 instance
$INSTANCE_ID = (terraform output -raw ec2_instance_ids | ConvertFrom-Json)[0]
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]'
```

### Step 6.3: Get Application URL

```powershell
# Get ALB DNS name
$ALB_DNS = terraform output -raw alb_dns_name
Write-Host "Application URL: http://$ALB_DNS"

# Test it
curl "http://$ALB_DNS"
```

---

## PHASE 7: Verify Deployment on EC2

### Step 7.1: SSH into EC2

```powershell
# Get instance public IP
$INSTANCE_IP = (terraform output -raw ec2_instance_public_ips | ConvertFrom-Json)[0]

# SSH into instance
ssh -i "$env:USERPROFILE\.ssh\portfolio-website" ec2-user@$INSTANCE_IP
```

### Step 7.2: Check Docker on EC2

```bash
# Once you're SSH'd into the instance
# Check running containers
docker ps

# Check application logs
docker logs portfolio-website

# Check Docker image
docker images

# Test locally on EC2
curl http://localhost:5000

# Exit SSH
exit
```

---

## PHASE 8: Test CI/CD Pipeline

### Step 8.1: Make a Change and Push

```powershell
# Go to your project directory
cd c:\Users\Devops\Portfolio_website\Portfolio_devops

# Make a small change to app.py or a template file
# (Edit any file and save)

# Commit and push
git add .
git commit -m "Test CI/CD pipeline - automatic deployment"
git push origin main
```

### Step 8.2: Watch Pipeline Execute

1. Go to GitHub → Actions
2. Click on the new workflow run
3. Watch it:
   - ✅ Validate Terraform
   - ✅ Build Docker image
   - ✅ Push to ECR
   - ✅ Deploy to EC2

### Step 8.3: Verify Updated Application

```powershell
# After deployment completes (takes ~5-10 minutes)
$ALB_DNS = terraform output -raw alb_dns_name

# Visit your application
Start-Process "http://$ALB_DNS"

# Or test with curl
curl "http://$ALB_DNS"
```

---

## PHASE 9: Troubleshooting

### Problem: GitHub Actions Shows Error

**Check logs:**
```powershell
# Go to GitHub → Actions → Click failed job → View logs
```

### Problem: ECR Login Fails

**Solution:**
```powershell
# Verify EC2 instance has proper IAM role
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

### Problem: EC2 Instance Not Healthy

**SSH in and check:**
```bash
docker logs portfolio-website
docker ps -a
docker stats
```

### Problem: Terraform Destroy Issues

**Clean up manually:**
```powershell
# Destroy infrastructure
cd terraform
terraform destroy

# Delete S3 bucket
aws s3 rm s3://portfolio-website-terraform-state --recursive
aws s3api delete-bucket --bucket portfolio-website-terraform-state --region us-east-1

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks --region us-east-1

# Delete IAM role
aws iam delete-role-policy --role-name GitHubActionsRole --policy-name GitHubActionsPolicy
aws iam delete-role --role-name GitHubActionsRole
```

---

## Summary: What Gets Deployed

When you push code:

```
Your Push to main
        ↓
GitHub Actions Triggered
        ↓
┌─────────────────────────────┐
│ 1. Terraform Validation     │ ← Validates infrastructure-as-code
├─────────────────────────────┤
│ 2. Docker Build & Push      │ ← Builds container, pushes to ECR
├─────────────────────────────┤
│ 3. EC2 Deployment           │ ← Pulls image and runs on EC2
└─────────────────────────────┘
        ↓
Application Live at: http://ALB-DNS-Name
```

---

## Files You Created

```
Portfolio_devops/
├── Dockerfile                          # Multi-stage Docker build
├── docker-compose.yml                  # Local dev environment
├── .dockerignore                       # Exclude files from image
├── .gitignore                          # Git ignore patterns
├── SETUP_GUIDE.md                      # Detailed guide (this file)
├── requirements.txt                    # Python dependencies
├── app.py                              # Flask app
├── .github/
│   └── workflows/
│       └── cicd.yml                   # GitHub Actions workflow
└── terraform/
    ├── provider.tf                    # AWS provider
    ├── variables.tf                   # Variables
    ├── data.tf                        # Data sources
    ├── vpc.tf                         # VPC setup
    ├── security_groups.tf             # Security rules
    ├── ecr.tf                         # Docker registry
    ├── iam.tf                         # Roles & permissions
    ├── ec2.tf                         # Compute & load balancer
    ├── user_data.sh                   # EC2 startup script
    └── outputs.tf                     # Output values
```

---

## Key Endpoints

- **Application**: http://[ALB-DNS-Name]
- **GitHub Actions**: https://github.com/[USERNAME]/portfolio-website/actions
- **AWS EC2 Console**: https://us-east-1.console.aws.amazon.com/ec2/
- **AWS ECR Console**: https://us-east-1.console.aws.amazon.com/ecr/

---

## Next Steps

1. ✅ Complete all 9 phases above
2. ✅ Push code and watch pipeline
3. ✅ Access your live application
4. ✅ Make changes and auto-deploy via git push
5. 🚀 Scale by adding more EC2 instances (change `instance_count` in Terraform)

**Congratulations! Your CI/CD pipeline is live!** 🎉
