# 🚀 Portfolio Website - Live Deployment Guide

**Status**: Ready for Live Deployment  
**Infrastructure**: AWS S3 + Terraform + GitHub Actions  
**Account ID**: 827739413634  
**GitHub User**: ahmadamir1509  

---

## 📋 What's Already Done

✅ **Terraform Configuration**
- S3 bucket resources defined
- Website hosting configuration
- Public access policies
- All validation tests pass

✅ **GitHub Actions Workflow**
- Terraform validation job
- S3 deployment job
- Automated on git push

✅ **Project Files**
- Modern responsive HTML homepage
- Error page (404 handling)
- Git repository initialized
- All dependencies in place

---

## ⚡ Quick Start - 3 Simple Steps

### Step 1: Execute Deployment Script (2 minutes)

```powershell
# Option A: Run batch file (Windows)
c:\Users\Devops\Portfolio_website\Portfolio_devops\DEPLOY.bat

# Option B: Manual execution (see below)
```

**What this does:**
- ✅ Creates OIDC provider for GitHub
- ✅ Creates GitHub Actions IAM role
- ✅ Initializes Terraform
- ✅ Validates infrastructure code
- ✅ Creates S3 bucket
- ✅ Initializes Git repository

### Step 2: Add GitHub Secret (1 minute)

1. **Go to**: https://github.com/ahmadamir1509/portfolio-website/settings/secrets/actions
2. **Click**: "New repository secret"
3. **Add**:
   - **Name**: `AWS_ROLE_ARN`
   - **Value**: (Copy from `AWS_ROLE_ARN.txt` file created by deploy script)
4. **Save**

### Step 3: Push Code to GitHub (30 seconds)

```powershell
cd c:\Users\Devops\Portfolio_website\Portfolio_devops
git push -u origin main
```

**What happens automatically:**
- GitHub Actions triggers
- Terraform validates code
- HTML/CSS uploaded to S3
- Website goes LIVE! 🎉

---

## 🔧 Manual Execution (If Script Doesn't Work)

Follow [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md) file for step-by-step commands.

### Quick Commands:

```powershell
# 1. Create OIDC Provider
aws iam create-open-id-connect-provider `
  --url https://token.actions.githubusercontent.com `
  --client-id-list sts.amazonaws.com `
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Get Account ID
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# 3. Create Role (create trust policy first - see DEPLOYMENT_STEPS.md)
aws iam create-role `
  --role-name GitHubActionsRole `
  --assume-role-policy-document file://$env:TEMP\trust-policy.json

# 4. Attach Policy
aws iam put-role-policy `
  --role-name GitHubActionsRole `
  --policy-name GitHubActionsPolicy `
  --policy-document file://$env:TEMP\policy.json

# 5. Get Role ARN
aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text

# 6. Initialize Terraform
cd terraform
terraform init -backend=false
terraform validate
terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1" -out=tfplan
terraform apply -auto-approve tfplan

# 7. Get Website URL
terraform output website_domain

# 8. Setup Git
cd ..
git init
git config user.name "DevOps"
git config user.email "devops@portfolio.local"
git remote add origin https://github.com/ahmadamir1509/portfolio-website.git
git add .
git commit -m "Initial deployment"
git branch -M main

# 9. Push (after adding GitHub secret)
git push -u origin main
```

---

## 📊 Deployment Architecture

```
┌─────────────────────────────────────┐
│      Your Local Machine             │
│  ┌─────────────────────────────────┐│
│  │ Git Repository                  ││
│  │ ├─ index.html                   ││
│  │ ├─ error.html                   ││
│  │ ├─ terraform/                   ││
│  │ └─ .github/workflows/           ││
│  └────────────┬──────────────────┘│
└───────────────┼───────────────────┘
                │ git push origin main
                ▼
┌──────────────────────────────────────┐
│      GitHub Repository               │
│  ├─ Code stored                      │
│  └─ Triggers GitHub Actions          │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│      GitHub Actions Workflow         │
│  ├─ terraform-validate               │
│  │  └─ Validates code                │
│  └─ deploy                           │
│     ├─ terraform apply               │
│     ├─ upload HTML to S3             │
│     └─ print website URL             │
└──────────────────┬────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│         AWS Infrastructure            │
│  ┌──────────────────────────────────┐│
│  │  S3 Bucket                       ││
│  │  (noor-portfolio-website)        ││
│  │  ├─ index.html                   ││
│  │  ├─ error.html                   ││
│  │  └─ Website Hosting Enabled      ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
                   │
                   ▼
        🌐 WEBSITE LIVE! 🌐
        http://noor-portfolio-website
        .s3-website-us-east-1
        .amazonaws.com
```

---

## 📁 File Structure

```
Portfolio_devops/
├── index.html                        # Homepage (deployed)
├── error.html                        # Error page (deployed)
├── DEPLOY.bat                        # ← RUN THIS FIRST
├── DEPLOYMENT_STEPS.md               # Step-by-step manual guide
├── SETUP_GUIDE.md                    # Architecture & details
├── COMMANDS.md                       # Copy-paste commands
├── README.md                         # This file
│
├── .github/
│   └── workflows/
│       └── cicd.yml                 # Auto-deployment workflow
│
├── terraform/
│   ├── provider.tf                  # AWS configuration
│   ├── variables.tf                 # Input variables
│   ├── vpc.tf                       # S3 bucket & policies
│   ├── outputs.tf                   # Output values
│   ├── data.tf                      # Data sources
│   ├── security_groups.tf           # (empty - not needed)
│   ├── ecr.tf                       # (empty - not needed)
│   ├── iam.tf                       # (empty - not needed)
│   └── ec2.tf                       # (empty - not needed)
│
├── aws/
│   └── README.md                    # AWS documentation
│
└── static/
    └── css/
        └── styles.css               # Optional stylesheets
```

---

## ✅ Validation Checklist

Before going live, verify:

- [ ] AWS CLI working: `aws sts get-caller-identity`
- [ ] Terraform installed: `terraform version`
- [ ] Git installed: `git --version`
- [ ] AWS credentials configured: `aws configure`
- [ ] GitHub account has admin access to repository
- [ ] Repository exists: https://github.com/ahmadamir1509/portfolio-website

---

## 🔐 Security Notes

- **No server management** - Static files only
- **S3 bucket public** - But only for reading (GET)
- **No database** - No backend code
- **Minimal IAM** - Only S3 permissions
- **OIDC token-based** - GitHub authenticates with AWS securely

---

## 📊 Testing Checklist

After deployment:

1. **GitHub Actions**
   - [ ] Go to https://github.com/ahmadamir1509/portfolio-website/actions
   - [ ] Check all jobs are green ✓
   - [ ] View logs for deployed URL

2. **Website**
   - [ ] Open website URL in browser
   - [ ] Homepage loads with styling
   - [ ] Mobile responsive (try resize)
   - [ ] Check S3 console for uploaded files

3. **S3 Bucket**
   - [ ] List files: `aws s3 ls s3://noor-portfolio-website/`
   - [ ] Check bucket policy allows public read
   - [ ] Verify website configuration enabled

---

## 🔄 Auto-Deployment (Future Updates)

After first deployment, any git push auto-deploys:

```powershell
# Edit your website
code index.html

# Push changes
git add .
git commit -m "Update portfolio content"
git push origin main

# Watch GitHub Actions deploy automatically!
# Website updates within 2-3 minutes
```

---

## 🆘 Troubleshooting

### Issue: GitHub Actions fails
**Solution**: 
- Check `AWS_ROLE_ARN` secret value is exactly correct
- Verify OIDC provider exists: `aws iam list-open-id-connect-providers`

### Issue: Website returns 403 Forbidden
**Solution**:
- Run: `terraform apply` again
- Wait 1-2 minutes for S3 to sync permissions

### Issue: Files not uploading
**Solution**:
- Check S3 bucket exists: `aws s3 ls`
- Verify bucket name matches: `noor-portfolio-website`
- Check bucket policy: `aws s3api get-bucket-policy --bucket noor-portfolio-website`

### Issue: Terraform fails
**Solution**:
- Run validation: `terraform validate`
- Check AWS credentials: `aws sts get-caller-identity`
- Verify S3 bucket name is available (globally unique)

---

## 📞 Support

**For AWS issues**:
```powershell
# View Terraform state
cd terraform
terraform show

# Check S3 bucket
aws s3 ls s3://noor-portfolio-website/

# View bucket policy
aws s3api get-bucket-policy --bucket noor-portfolio-website
```

**For Git issues**:
```powershell
# View commit history
git log --oneline

# Check remote
git remote -v

# Check status
git status
```

**For GitHub Actions issues**:
- Visit: https://github.com/ahmadamir1509/portfolio-website/actions
- Click failed job
- View full logs

---

## 🎯 Success Indicators

✅ All systems running when:

1. **GitHub Actions page shows**:
   - `terraform-validate` job: PASSED ✓
   - `deploy` job: PASSED ✓
   - No red X marks

2. **Website loads**:
   - HTTP 200 OK response
   - Beautiful gradient background
   - Responsive on mobile
   - No 403/404 errors

3. **S3 bucket contains**:
   - `index.html`
   - `error.html`
   - Public read permissions set

4. **Git shows**:
   - All files committed
   - Remote set to GitHub
   - Branch is `main`

---

## 🚀 Go Live!

**You're ready!** Execute these steps in order:

1. **Run deployment script** (or follow manual steps)
2. **Add GitHub secret**
3. **Push code**: `git push -u origin main`
4. **Watch magic happen**: GitHub Actions deploys automatically
5. **Visit your website**: Open the S3 URL
6. **Share with world**: Your portfolio is live! 🎉

---

## 📚 Documentation Files

- **DEPLOYMENT_STEPS.md** - Detailed step-by-step guide
- **COMMANDS.md** - Copy-paste command reference
- **SETUP_GUIDE.md** - Architecture and concepts
- **README.md** - This file

---

**Created**: December 16, 2025  
**Status**: Production Ready  
**Next Step**: Execute DEPLOY.bat or follow DEPLOYMENT_STEPS.md
