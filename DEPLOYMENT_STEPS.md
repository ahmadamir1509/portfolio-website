# LIVE DEPLOYMENT - Step by Step Execution

## Account Details (Already Verified)
- **Account ID**: 827739413634
- **GitHub Username**: ahmadamir1509
- **Repository**: portfolio-website

---

## EXECUTION PHASE 1: AWS OIDC & IAM Setup

### Step 1: Create OIDC Provider

```powershell
aws iam create-open-id-connect-provider `
  --url https://token.actions.githubusercontent.com `
  --client-id-list sts.amazonaws.com `
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Expected Output**: OpenIDConnectProviderArn or "already exists"

### Step 2: Save Trust Policy for IAM Role

```powershell
$ACCOUNT_ID = "827739413634"
$GITHUB_USER = "ahmadamir1509"

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
                    "token.actions.githubusercontent.com:sub" = "repo:$($GITHUB_USER)/portfolio-website:*"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$TrustPolicy | Set-Content -Path "$env:TEMP\trust-policy.json" -Encoding UTF8

# Verify file created
Get-Content "$env:TEMP\trust-policy.json"
```

### Step 3: Create IAM Role for GitHub Actions

```powershell
aws iam create-role `
  --role-name GitHubActionsRole `
  --assume-role-policy-document "file://$env:TEMP\trust-policy.json"
```

**Expected Output**: Role ARN like `arn:aws:iam::827739413634:role/GitHubActionsRole`

### Step 4: Create and Attach IAM Policy

```powershell
$Policy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @("s3:*")
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

$Policy | Set-Content -Path "$env:TEMP\policy.json" -Encoding UTF8

aws iam put-role-policy `
  --role-name GitHubActionsRole `
  --policy-name GitHubActionsPolicy `
  --policy-document "file://$env:TEMP\policy.json"
```

### Step 5: Get Role ARN (SAVE THIS!)

```powershell
$ROLE_ARN = aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
Write-Host "Role ARN: $ROLE_ARN"
$ROLE_ARN | Set-Content -Path "C:\Users\Devops\Portfolio_website\Portfolio_devops\AWS_ROLE_ARN.txt"
```

---

## EXECUTION PHASE 2: Terraform Infrastructure

### Step 6: Navigate to Terraform Directory

```powershell
cd C:\Users\Devops\Portfolio_website\Portfolio_devops\terraform
```

### Step 7: Initialize Terraform

```powershell
terraform init -backend=false
```

**Expected Output**: "Terraform has been successfully configured!"

### Step 8: Validate Terraform Configuration

```powershell
terraform validate
```

**Expected Output**: "Success! The configuration is valid."

### Step 9: Plan Terraform Deployment

```powershell
terraform plan `
  -var="bucket_name=noor-portfolio-website" `
  -var="aws_region=us-east-1" `
  -out=tfplan
```

**Expected Output**: Shows resources to be created:
- aws_s3_bucket.website
- aws_s3_bucket_public_access_block.website
- aws_s3_bucket_policy.website
- aws_s3_bucket_website_configuration.website
- aws_s3_bucket_versioning.website

### Step 10: Apply Terraform (Create S3 Bucket)

```powershell
terraform apply -auto-approve tfplan
```

**Expected Output**: "Apply complete! Resources: 5 added, 0 changed, 0 destroyed."

### Step 11: Get Outputs

```powershell
terraform output bucket_name
terraform output website_url
terraform output website_domain
```

**Save these URLs - they're your website!**

---

## EXECUTION PHASE 3: Git Repository Setup

### Step 12: Navigate Back to Project Root

```powershell
cd C:\Users\Devops\Portfolio_website\Portfolio_devops
```

### Step 13: Initialize Git (if not already done)

```powershell
git init
git config user.name "DevOps Engineer"
git config user.email "devops@portfolio.local"
```

### Step 14: Check/Add Git Remote

```powershell
# Check existing remotes
git remote -v

# If no origin remote, add it
git remote add origin https://github.com/ahmadamir1509/portfolio-website.git

# Verify it was added
git remote -v
```

### Step 15: Stage All Files

```powershell
git add .
```

### Step 16: Verify Files Staged

```powershell
git status
```

**Expected**: Shows all HTML, Terraform, workflow files ready to commit

### Step 17: Create Initial Commit

```powershell
git commit -m "Initial deployment: Static portfolio website with Terraform & GitHub Actions CI/CD"
```

### Step 18: Check Current Branch

```powershell
git branch
```

If not on `main`, rename:
```powershell
git branch -M main
```

---

## EXECUTION PHASE 4: GitHub Configuration

### Step 19: Add GitHub Secret (CRITICAL!)

1. Go to: https://github.com/ahmadamir1509/portfolio-website/settings/secrets/actions
2. Click **New repository secret**
3. **Name**: `AWS_ROLE_ARN`
4. **Value**: (Paste the role ARN from Step 5)
   - Should look like: `arn:aws:iam::827739413634:role/GitHubActionsRole`
5. Click **Add secret**

---

## EXECUTION PHASE 5: Deploy to GitHub (FINAL PUSH)

### Step 20: Push Code to GitHub

```powershell
git push -u origin main
```

**Expected Output**: 
```
Enumerating objects: XX, done.
Counting objects: 100% (XX/XX), done.
...
To https://github.com/ahmadamir1509/portfolio-website.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

---

## EXECUTION PHASE 6: Monitor GitHub Actions

### Step 21: Check GitHub Actions

1. Go to: https://github.com/ahmadamir1509/portfolio-website/actions
2. You should see workflow running:
   - **Job 1: terraform-validate**
     - ✓ Checkout code
     - ✓ Setup Terraform
     - ✓ Terraform Format Check
     - ✓ Terraform Init
     - ✓ Terraform Validate
   
   - **Job 2: deploy**
     - ✓ Checkout code
     - ✓ Configure AWS credentials
     - ✓ Setup Terraform
     - ✓ Terraform Init
     - ✓ Terraform Apply
     - ✓ Get Website URL
     - ✓ Upload HTML files to S3
     - ✓ Print Website URL

### Step 22: Wait for Deployment

- Job should complete in 2-3 minutes
- All checkmarks should be green
- Look for "Print Website URL" section

---

## EXECUTION PHASE 7: Verify Website is Live

### Step 23: Get Website URL

From GitHub Actions output, find the website URL. It should be:
```
http://noor-portfolio-website.s3-website-us-east-1.amazonaws.com
```

Or get it from Terraform:
```powershell
cd terraform
terraform output website_domain
```

### Step 24: Test Website

Open in browser or run:
```powershell
$URL = (cd terraform; terraform output -raw website_domain)
Start-Process $URL
```

**Expected**: Beautiful responsive portfolio website with gradient background loads!

### Step 25: Verify S3 Bucket Contents

```powershell
aws s3 ls s3://noor-portfolio-website/
```

**Expected Output**:
```
2025-12-16 10:30:00     XXXX index.html
2025-12-16 10:30:00     YYYY error.html
```

---

## VALIDATION CHECKLIST

✅ **Phase 1: AWS Setup**
- [x] OIDC Provider created
- [x] GitHub Actions IAM Role created
- [x] Role ARN saved

✅ **Phase 2: Terraform**
- [x] Terraform init successful
- [x] Terraform validate passed
- [x] Terraform plan created
- [x] Terraform apply successful
- [x] S3 bucket created

✅ **Phase 3: Git**
- [x] Git repository initialized
- [x] Git remote added
- [x] Files staged and committed

✅ **Phase 4: GitHub**
- [x] AWS_ROLE_ARN secret added
- [x] Code pushed to main branch

✅ **Phase 5: GitHub Actions**
- [x] terraform-validate job passed
- [x] deploy job passed
- [x] HTML uploaded to S3

✅ **Phase 6: Live Website**
- [x] Website accessible at S3 URL
- [x] index.html loads successfully
- [x] Responsive design works

---

## Troubleshooting

### If GitHub Actions fails:

**"Access Denied" error**:
1. Check AWS_ROLE_ARN secret is correct
2. Verify OIDC provider exists
3. Re-push changes

**"Terraform plan failed"**:
1. Check terraform files syntax
2. Run: `terraform validate` locally
3. Verify AWS credentials

**Website returns 403**:
1. Run: `terraform apply` again
2. Check bucket policy:
   ```powershell
   aws s3api get-bucket-policy --bucket noor-portfolio-website
   ```
3. Wait 1-2 minutes for S3 to sync

### If files didn't upload:

```powershell
# Manually upload HTML files
aws s3 cp index.html s3://noor-portfolio-website/ --content-type "text/html"
aws s3 cp error.html s3://noor-portfolio-website/ --content-type "text/html"
```

---

## Success Indicators

When everything is working:

1. ✅ GitHub Actions shows all green checkmarks
2. ✅ Website URL accessible in browser
3. ✅ Portfolio page displays with styling
4. ✅ S3 bucket contains index.html and error.html
5. ✅ Future git pushes auto-deploy changes

**Your portfolio website is LIVE!** 🚀

---

## Next: Update Website Content

Edit `index.html` with your own content:

```powershell
# Edit your HTML
notepad index.html

# Commit and push
git add index.html
git commit -m "Update portfolio content"
git push origin main

# Watch GitHub Actions auto-deploy!
```

Every git push automatically:
1. Validates Terraform
2. Deploys infrastructure
3. Uploads HTML files
4. Website updates live!
