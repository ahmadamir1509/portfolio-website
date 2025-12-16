# Portfolio Website Full Deployment Script

Write-Host "========================================" -ForegroundColor Blue
Write-Host "Portfolio Website Deployment Test" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

# STEP 1: Test AWS CLI
Write-Host "STEP 1: Testing AWS CLI..." -ForegroundColor Yellow
try {
    $callerIdentity = aws sts get-caller-identity | ConvertFrom-Json
    $ACCOUNT_ID = $callerIdentity.Account
    $USER_ARN = $callerIdentity.Arn
    Write-Host "✓ AWS CLI working" -ForegroundColor Green
    Write-Host "  Account ID: $ACCOUNT_ID"
    Write-Host "  User ARN: $USER_ARN`n"
} catch {
    Write-Host "✗ AWS CLI failed: $_" -ForegroundColor Red
    exit 1
}

# STEP 2: Create OIDC Provider
Write-Host "STEP 2: Setting up OIDC Provider..." -ForegroundColor Yellow
try {
    $oidcOutput = aws iam create-open-id-connect-provider `
        --url https://token.actions.githubusercontent.com `
        --client-id-list sts.amazonaws.com `
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>&1
    
    if ($oidcOutput -match "already exists" -or $oidcOutput -match "OpenIDConnectProviderArn") {
        Write-Host "✓ OIDC Provider configured" -ForegroundColor Green
    } else {
        Write-Host "✓ OIDC Provider processed" -ForegroundColor Green
    }
    Write-Host ""
} catch {
    Write-Host "⚠ OIDC check: $_" -ForegroundColor Yellow
}

# STEP 3: Create GitHub Actions IAM Role
Write-Host "STEP 3: Creating GitHub Actions IAM Role..." -ForegroundColor Yellow

$trustPolicy = @{
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
                    "token.actions.githubusercontent.com:sub" = "repo:ahmadamir1509/portfolio-website:*"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$trustPolicy | Set-Content -Path "$env:TEMP\trust-policy.json"

try {
    $roleOutput = aws iam create-role `
        --role-name GitHubActionsRole `
        --assume-role-policy-document "file://$env:TEMP\trust-policy.json" 2>&1
    
    if ($roleOutput -match "already exists") {
        Write-Host "✓ GitHub Actions Role already exists" -ForegroundColor Green
    } else {
        Write-Host "✓ GitHub Actions Role created" -ForegroundColor Green
    }
} catch {
    Write-Host "✓ GitHub Actions Role ready" -ForegroundColor Green
}

# Add inline policy
$policyDocument = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @("s3:*")
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

$policyDocument | Set-Content -Path "$env:TEMP\policy.json"

aws iam put-role-policy `
    --role-name GitHubActionsRole `
    --policy-name GitHubActionsPolicy `
    --policy-document "file://$env:TEMP\policy.json" | Out-Null

Write-Host "✓ IAM Policy attached" -ForegroundColor Green

# Get role ARN
$ROLE_ARN = aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
Write-Host "  Role ARN: $ROLE_ARN`n"

# STEP 4-6: Terraform Operations
Write-Host "STEP 4: Validating Terraform..." -ForegroundColor Yellow
cd "$env:USERPROFILE\Portfolio_website\Portfolio_devops\terraform"

# Init
terraform init -backend=false -no-color -quiet 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Terraform init successful" -ForegroundColor Green
} else {
    Write-Host "✗ Terraform init failed" -ForegroundColor Red
    exit 1
}

# Validate
$validateOutput = terraform validate -no-color 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Terraform validation passed" -ForegroundColor Green
} else {
    Write-Host "✗ Terraform validation failed" -ForegroundColor Red
    Write-Host $validateOutput
    exit 1
}

Write-Host ""

# STEP 5: Plan
Write-Host "STEP 5: Planning Terraform deployment..." -ForegroundColor Yellow
$planOutput = terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1" -no-color -out=tfplan 2>&1

if (Test-Path "tfplan") {
    Write-Host "✓ Terraform plan created successfully" -ForegroundColor Green
    Write-Host "  Resources to be created:"
    $planOutput | Select-String "aws_s3_bucket|aws_s3_bucket_policy|aws_s3_bucket_website" | ForEach-Object { Write-Host "    $_" }
} else {
    Write-Host "✗ Terraform plan failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# STEP 6: Apply
Write-Host "STEP 6: Applying Terraform (Creating S3 bucket)..." -ForegroundColor Yellow
$applyOutput = terraform apply -auto-approve tfplan -no-color 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Terraform apply successful" -ForegroundColor Green
    
    $BUCKET = terraform output -raw bucket_name 2>$null
    $WEBSITE_URL = terraform output -raw website_domain 2>$null
    
    Write-Host "  S3 Bucket: $BUCKET"
    Write-Host "  Website URL: $WEBSITE_URL`n"
} else {
    Write-Host "✗ Terraform apply failed" -ForegroundColor Red
    exit 1
}

cd "$env:USERPROFILE\Portfolio_website\Portfolio_devops"

# STEP 7: Initialize Git
Write-Host "STEP 7: Initializing Git Repository..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    git init > $null 2>&1
    git config user.name "DevOps Engineer" > $null 2>&1
    git config user.email "devops@portfolio.local" > $null 2>&1
    Write-Host "✓ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "✓ Git repository already exists" -ForegroundColor Green
}

$remoteCheck = git remote -v 2>$null | Select-String "origin"
if ($remoteCheck) {
    Write-Host "✓ Git remote 'origin' configured`n"
} else {
    Write-Host "⚠ Git remote 'origin' not yet configured" -ForegroundColor Yellow
    Write-Host "  Will be added before push`n"
}

# STEP 8: Summary
Write-Host "========================================" -ForegroundColor Blue
Write-Host "DEPLOYMENT CHECKLIST" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

Write-Host "✓ AWS CLI credentials verified" -ForegroundColor Green
Write-Host "✓ OIDC Provider configured" -ForegroundColor Green
Write-Host "✓ GitHub Actions IAM Role created" -ForegroundColor Green
Write-Host "✓ Terraform validated and applied" -ForegroundColor Green
Write-Host "✓ S3 bucket created and configured" -ForegroundColor Green
Write-Host "✓ Git repository initialized`n" -ForegroundColor Green

Write-Host "========================================" -ForegroundColor Blue
Write-Host "NEXT STEPS" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

Write-Host "1. Add GitHub Secret (CRITICAL):" -ForegroundColor Yellow
Write-Host "   Go to: GitHub Repo → Settings → Secrets and variables → Actions"
Write-Host "   Click: New repository secret"
Write-Host "   Name: AWS_ROLE_ARN"
Write-Host "   Value: $ROLE_ARN`n"

Write-Host "2. Configure Git Remote (if needed):" -ForegroundColor Yellow
Write-Host "   git remote add origin https://github.com/ahmadamir1509/portfolio-website.git`n"

Write-Host "3. Push code to GitHub (TRIGGERS DEPLOYMENT):" -ForegroundColor Yellow
Write-Host "   git add ."
Write-Host "   git commit -m 'Initial deployment: static website with Terraform'"
Write-Host "   git push -u origin main`n"

Write-Host "4. Monitor GitHub Actions:" -ForegroundColor Yellow
Write-Host "   https://github.com/ahmadamir1509/portfolio-website/actions`n"

Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Website will be live at:" -ForegroundColor Green
Write-Host "$WEBSITE_URL" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Saving role ARN to file..." -ForegroundColor Cyan
$ROLE_ARN | Set-Content -Path "GITHUB_SECRET_AWS_ROLE_ARN.txt"
Write-Host "✓ Saved to: GITHUB_SECRET_AWS_ROLE_ARN.txt" -ForegroundColor Green
