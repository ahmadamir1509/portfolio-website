# Static Website Deployment with Terraform & GitHub Actions

This project demonstrates deploying a static website to AWS S3 using Terraform Infrastructure as Code with automated CI/CD via GitHub Actions.

## What We're Building

```
GitHub Repository
    ↓ (Push to main)
GitHub Actions CI/CD
    ├─ Terraform Validate
    └─ Terraform Apply → Deploy to S3
        ↓
AWS S3 Static Website (Live)
```

## Prerequisites

- AWS Account with S3 permissions
- GitHub Account & Repository
- Terraform installed (v1.0+)
- AWS CLI v2 configured
- Git installed

---

## STEP 1: Set Up AWS Prerequisites

### 1.1 Create IAM Role for GitHub Actions

```bash
# Create trust policy file
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/portfolio-website:*"
        }
      }
    }
  ]
}
EOF
```

Replace `ACCOUNT_ID` and `YOUR_GITHUB_USERNAME` in the file, then:

```bash
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Create policy for S3 and Terraform access
cat > github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "terraform:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json

# Get the role ARN
aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
```

### 1.2 Set Up OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

---

## STEP 2: GitHub Configuration

### 2.1 Add GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Click **"New repository secret"** and add:

- **AWS_ROLE_ARN**: `arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole` (from Step 1.1)

---

## STEP 3: Deploy with Terraform

### 3.1 Initialize Terraform

```bash
cd terraform
terraform init -backend=false
terraform validate
```

### 3.2 Plan Infrastructure

```bash
terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1"
```

### 3.3 Apply Infrastructure

```bash
terraform apply -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1"
```

**This creates:**
- ✅ S3 bucket for website hosting
- ✅ Bucket policies for public access
- ✅ Website configuration (index.html, error.html)

---

## STEP 4: Push Code to GitHub

```bash
cd c:\Users\Devops\Portfolio_website\Portfolio_devops

git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

git init
git remote add origin https://github.com/YOUR_USERNAME/portfolio-website.git

git add .
git commit -m "Initial commit: Static website with Terraform & GitHub Actions"
git branch -M main
git push -u origin main
```

This triggers the GitHub Actions pipeline!

---

## STEP 5: Monitor Deployment

1. Go to GitHub → **Actions** tab
2. Click on the running workflow
3. Watch **terraform-validate** and **deploy** jobs execute
4. Get the S3 website URL from Terraform outputs:

```bash
cd terraform
terraform output website_domain
```

Visit the URL in your browser! 🎉

---

## STEP 6: Update & Auto-Deploy

Make changes to your website and push:

```bash
# Edit index.html or other files
git add .
git commit -m "Update website content"
git push origin main
```

GitHub Actions automatically:
1. ✅ Validates Terraform code
2. ✅ Deploys infrastructure if needed
3. ✅ Uploads HTML/CSS files to S3
4. ✅ Website updates instantly

---

## File Structure

```
Portfolio_devops/
├── index.html                          # Homepage
├── error.html                          # Error page
├── .gitignore                          # Git ignore
├── SETUP_GUIDE.md                      # This guide
├── .github/
│   └── workflows/
│       └── cicd.yml                   # GitHub Actions workflow
└── terraform/
    ├── provider.tf                    # AWS provider
    ├── variables.tf                   # Input variables
    ├── data.tf                        # Data sources
    ├── vpc.tf                         # S3 bucket configuration
    ├── security_groups.tf             # (Empty - not needed)
    ├── ecr.tf                         # (Empty - not needed)
    ├── iam.tf                         # (Empty - not needed)
    ├── ec2.tf                         # (Empty - not needed)
    └── outputs.tf                     # Output values
```

---

## Terraform Outputs

After deployment, get these values:

```bash
cd terraform
terraform output bucket_name       # S3 bucket name
terraform output website_url       # Website endpoint
terraform output website_domain    # Full website URL
```

---

## Cleanup

To destroy everything:

```bash
cd terraform
terraform destroy -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1"

# Delete IAM role
aws iam delete-role-policy --role-name GitHubActionsRole --policy-name GitHubActionsPolicy
aws iam delete-role --role-name GitHubActionsRole
```

---

## Key Features

✅ **Infrastructure as Code** - Terraform manages all resources  
✅ **Automated CI/CD** - GitHub Actions validates and deploys  
✅ **Minimal Setup** - No servers, just static files  
✅ **Cost Effective** - Pay only for S3 storage  
✅ **Fast Deployment** - CloudFront ready (optional upgrade)  
✅ **Version Control** - All changes tracked in Git  

---

## Troubleshooting

**GitHub Actions fails:**
- Check AWS_ROLE_ARN secret is correct
- Verify OIDC provider exists

**S3 bucket permissions denied:**
- Run: `terraform apply` again
- Check bucket policy is correct

**Website shows 403 Forbidden:**
- Ensure bucket name is globally unique
- Check bucket policy allows public read

---

## Next Steps

1. ✅ Complete all steps above
2. ✅ Push code and watch pipeline
3. ✅ Access your live S3 website
4. ✅ Share your website URL!

**Congratulations! Your static website is live!** 🚀


```bash
# Create trust policy file: trust-policy.json
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/portfolio-website:*"
        }
      }
    }
  ]
}
EOF

# Replace ACCOUNT_ID and YOUR_GITHUB_USERNAME in the file above

# Create the role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Create inline policy for GitHub Actions
cat > github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "iam:PassRole",
        "logs:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json
```

---

## STEP 2: Configure GitHub Repository

### 2.1 Set Up OIDC Provider (if not exists)

```bash
# Add OIDC provider to GitHub
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  2>/dev/null || echo "Provider already exists"
```

### 2.2 Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

1. **AWS_ROLE_ARN**: Get this from the role you created
   ```bash
   aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn'
   ```

2. **EC2_SSH_PRIVATE_KEY**: Your EC2 SSH private key (base64 encoded)
   ```bash
   # Generate new SSH key pair (if you don't have one)
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/portfolio-website -N ""
   
   # Get the private key in base64
   cat ~/.ssh/portfolio-website | base64 -w 0
   ```

---

## STEP 3: Deploy Infrastructure with Terraform

### 3.1 Initialize Terraform Backend

```bash
cd terraform

# Set your AWS region and credentials
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

# Initialize Terraform
terraform init
```

### 3.2 Validate Terraform Configuration

```bash
terraform validate
terraform fmt -recursive
```

### 3.3 Plan Infrastructure Deployment

```bash
terraform plan -out=tfplan
```

### 3.4 Apply Terraform Configuration

```bash
terraform apply tfplan
```

**Note:** This will create:
- VPC with public subnets
- Internet Gateway
- Security Groups (ALB and EC2)
- ECR Repository
- EC2 instances
- Application Load Balancer
- Target Groups
- IAM roles and policies

### 3.5 Save Terraform Outputs

```bash
# Get the outputs
terraform output

# Save them for later reference
terraform output -json > outputs.json
```

---

## STEP 4: Import SSH Key to EC2

### 4.1 Create Key Pair in AWS

```bash
# Create key pair
aws ec2 import-key-pair \
  --key-name portfolio-website-key \
  --public-key-material fileb://~/.ssh/portfolio-website.pub \
  --region us-east-1
```

### 4.2 Update Security Group for SSH Access

```bash
# Get the security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=portfolio-website-ec2-sg \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Add your IP for SSH (replace YOUR_IP)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32 \
  --region us-east-1
```

---

## STEP 5: Test Local Docker Build

### 5.1 Build Docker Image Locally

```bash
# From your project directory
docker build -t portfolio-website:latest .
```

### 5.2 Run Container Locally

```bash
docker run -d \
  --name portfolio-website-local \
  -p 5000:5000 \
  -e FLASK_ENV=production \
  portfolio-website:latest

# Test the application
curl http://localhost:5000

# Stop the container
docker stop portfolio-website-local
docker rm portfolio-website-local
```

### 5.3 Test with Docker Compose

```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

---

## STEP 6: Push Code to GitHub and Trigger Pipeline

### 6.1 Initialize Git Repository (if not already)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

cd c:\Users\Devops\Portfolio_website\Portfolio_devops

# Initialize git
git init

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/portfolio-website.git
```

### 6.2 Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
.egg-info/
.installed.cfg
*.egg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.env
.env.local

# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars

# Docker
docker-compose.override.yml
EOF
```

### 6.3 Commit and Push Code

```bash
git add .
git commit -m "Initial commit: Add CI/CD pipeline with Docker, Terraform, and GitHub Actions"
git branch -M main
git push -u origin main
```

This will trigger the CI/CD pipeline!

---

## STEP 7: Monitor Pipeline Execution

### 7.1 View GitHub Actions Logs

1. Go to your GitHub repository
2. Click "Actions" tab
3. Click on the latest workflow run
4. View logs for each job:
   - Terraform Validation
   - Build and Push Docker Image
   - Deploy to EC2

### 7.2 Verify Deployment

```bash
# Get ALB DNS name from Terraform outputs
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test the application
curl http://$ALB_DNS

# Or open in browser
# http://<ALB_DNS>
```

### 7.3 SSH into EC2 Instance

```bash
# Get instance IP
INSTANCE_IP=$(terraform output -raw ec2_instance_public_ips | jq -r '.[0]')

# SSH into instance
ssh -i ~/.ssh/portfolio-website ec2-user@$INSTANCE_IP

# Check Docker containers
docker ps

# Check application logs
docker logs portfolio-website

# Exit SSH
exit
```

---

## STEP 8: Monitor and Troubleshoot

### 8.1 Check CloudWatch Logs

```bash
# View CloudWatch logs
aws logs tail /aws/ec2/portfolio-website --follow
```

### 8.2 Check ALB Health

```bash
# Get target group ARN
TG_ARN=$(terraform output -raw alb_arn | sed 's/:loadbalancer//' | sed 's/\([^:]*:[^:]*:[^:]*:[^:]*\):.*/\1:targetgroup\/portfolio-website-tg\/*/' )

# Check targets
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region us-east-1
```

### 8.3 View Terraform State

```bash
# List resources
terraform state list

# Show specific resource
terraform state show 'aws_instance.web[0]'
```

---

## STEP 9: Setting Up Continuous Deployment Updates (Optional)

### 9.1 Manual Redeploy via GitHub Actions

Simply push code to main branch:

```bash
git add .
git commit -m "Update application"
git push origin main
```

The pipeline will:
1. ✅ Validate Terraform
2. ✅ Build Docker image
3. ✅ Push to ECR
4. ✅ Deploy to EC2

---

## Important Files Created

```
Portfolio_devops/
├── Dockerfile                          # Docker container definition
├── docker-compose.yml                  # Local Docker Compose setup
├── .dockerignore                       # Files to exclude from Docker build
├── .gitignore                          # Git ignore patterns
├── requirements.txt                    # Python dependencies
├── app.py                              # Flask application
├── .github/
│   └── workflows/
│       └── cicd.yml                   # GitHub Actions workflow
└── terraform/
    ├── provider.tf                    # AWS provider config
    ├── variables.tf                   # Terraform variables
    ├── data.tf                        # Data sources
    ├── vpc.tf                         # VPC and networking
    ├── security_groups.tf             # Security groups
    ├── ecr.tf                         # ECR repository
    ├── iam.tf                         # IAM roles and policies
    ├── ec2.tf                         # EC2 and ALB
    ├── user_data.sh                   # EC2 initialization script
    └── outputs.tf                     # Terraform outputs
```

---

## Troubleshooting Guide

### Pipeline Fails at Terraform Validation
- Ensure all variables are set correctly
- Check IAM permissions
- Verify AWS credentials

### Docker Build Fails
- Check requirements.txt syntax
- Ensure app.py is valid Python code
- Check Dockerfile paths

### EC2 Instance Not Healthy
- SSH into instance and check: `docker logs portfolio-website`
- Verify security groups allow traffic
- Check ALB target group health checks

### ECR Login Fails
- Verify IAM permissions on EC2
- Check AWS region configuration
- Ensure ECR repository exists

---

## Cleanup (When Done Testing)

```bash
# Destroy all AWS resources
cd terraform
terraform destroy

# Delete IAM role
aws iam delete-role-policy --role-name GitHubActionsRole --policy-name GitHubActionsPolicy
aws iam delete-role --role-name GitHubActionsRole
```

---

## Summary

Your CI/CD pipeline is now complete! Every time you push to the main branch:
1. Terraform validates infrastructure-as-code
2. Docker builds a container image
3. Image pushes to AWS ECR
4. Automatically deploys to EC2 via Application Load Balancer

The application is accessible via the ALB DNS name with automatic scaling and health checks!
