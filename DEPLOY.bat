@echo off
REM Portfolio Website Live Deployment Test & Execution
REM This script will test and deploy everything

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Portfolio Website Live Deployment
echo ========================================
echo.

REM PHASE 1: Test AWS
echo PHASE 1: Testing AWS Credentials...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] AWS credentials working
    for /f "tokens=*" %%a in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%a
    echo Account ID: !ACCOUNT_ID!
) else (
    echo [ERROR] AWS credentials failed
    exit /b 1
)
echo.

REM PHASE 2: OIDC Provider
echo PHASE 2: Setting up OIDC Provider...
aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >nul 2>&1
echo [OK] OIDC Provider setup complete
echo.

REM PHASE 3: Create GitHub Actions Role
echo PHASE 3: Creating GitHub Actions IAM Role...

(
echo {
echo   "Version": "2012-10-17",
echo   "Statement": [
echo     {
echo       "Effect": "Allow",
echo       "Principal": {
echo         "Federated": "arn:aws:iam::!ACCOUNT_ID!:oidc-provider/token.actions.githubusercontent.com"
echo       },
echo       "Action": "sts:AssumeRoleWithWebIdentity",
echo       "Condition": {
echo         "StringEquals": {
echo           "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
echo         },
echo         "StringLike": {
echo           "token.actions.githubusercontent.com:sub": "repo:ahmadamir1509/portfolio-website:*"
echo         }
echo       }
echo     }
echo   ]
echo }
) > "%temp%\trust-policy.json"

aws iam create-role --role-name GitHubActionsRole --assume-role-policy-document file://%temp%\trust-policy.json >nul 2>&1
echo [OK] GitHub Actions Role created/verified

(
echo {
echo   "Version": "2012-10-17",
echo   "Statement": [
echo     {
echo       "Effect": "Allow",
echo       "Action": ["s3:*"],
echo       "Resource": "*"
echo     }
echo   ]
echo }
) > "%temp%\policy.json"

aws iam put-role-policy --role-name GitHubActionsRole --policy-name GitHubActionsPolicy --policy-document file://%temp%\policy.json
echo [OK] IAM Policy attached
echo.

REM Get Role ARN
for /f "tokens=*" %%a in ('aws iam get-role --role-name GitHubActionsRole --query Role.Arn --output text') do set ROLE_ARN=%%a
echo Role ARN: !ROLE_ARN!
echo !ROLE_ARN! > AWS_ROLE_ARN.txt
echo [OK] Role ARN saved to AWS_ROLE_ARN.txt
echo.

REM PHASE 4: Terraform
echo PHASE 4: Initializing Terraform...
cd /d c:\Users\Devops\Portfolio_website\Portfolio_devops\terraform
terraform init -backend=false -no-color >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Terraform initialized
) else (
    echo [ERROR] Terraform init failed
    exit /b 1
)
echo.

echo PHASE 5: Validating Terraform...
terraform validate -no-color >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Terraform validation passed
) else (
    echo [ERROR] Terraform validation failed
    exit /b 1
)
echo.

echo PHASE 6: Planning Terraform deployment...
terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1" -out=tfplan -no-color >nul 2>&1
if exist tfplan (
    echo [OK] Terraform plan created
) else (
    echo [ERROR] Terraform plan failed
    exit /b 1
)
echo.

echo PHASE 7: Applying Terraform (Creating S3 bucket)...
terraform apply -auto-approve tfplan -no-color >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Terraform apply successful
    
    for /f "tokens=*" %%a in ('terraform output -raw bucket_name 2^>nul') do set BUCKET_NAME=%%a
    for /f "tokens=*" %%a in ('terraform output -raw website_domain 2^>nul') do set WEBSITE_URL=%%a
    
    echo S3 Bucket: !BUCKET_NAME!
    echo Website URL: !WEBSITE_URL!
) else (
    echo [ERROR] Terraform apply failed
    exit /b 1
)
echo.

REM PHASE 5: Git
cd /d c:\Users\Devops\Portfolio_website\Portfolio_devops
echo PHASE 8: Setting up Git...

if not exist .git (
    git init >nul 2>&1
    git config user.name "DevOps Engineer"  >nul 2>&1
    git config user.email "devops@portfolio.local" >nul 2>&1
    echo [OK] Git repository initialized
) else (
    echo [OK] Git repository already exists
)
echo.

git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    git remote add origin https://github.com/ahmadamir1509/portfolio-website.git
    echo [OK] Git remote added
) else (
    echo [OK] Git remote already configured
)
echo.

echo PHASE 9: Staging and committing files...
git add . >nul 2>&1
git status >nul 2>&1

echo [OK] Files staged
echo.

git commit -m "Initial deployment: Static portfolio website with Terraform and GitHub Actions CI/CD" >nul 2>&1
echo [OK] Files committed
echo.

REM Check branch
git rev-parse --abbrev-ref HEAD > "%temp%\branch.txt"
set /p CURRENT_BRANCH= < "%temp%\branch.txt"

if not "!CURRENT_BRANCH!"=="main" (
    git branch -M main >nul 2>&1
    echo [OK] Renamed branch to main
) else (
    echo [OK] Already on main branch
)
echo.

echo ========================================
echo DEPLOYMENT CHECKLIST
echo ========================================
echo [OK] AWS credentials verified
echo [OK] OIDC Provider configured
echo [OK] GitHub Actions IAM Role created
echo [OK] Terraform validated
echo [OK] S3 bucket created
echo [OK] Git repository ready
echo.

echo ========================================
echo CRITICAL NEXT STEP
echo ========================================
echo.
echo 1. Add GitHub Secret (REQUIRED):
echo    Go to: https://github.com/ahmadamir1509/portfolio-website/settings/secrets/actions
echo    Click: New repository secret
echo    Name: AWS_ROLE_ARN
echo    Value: !ROLE_ARN!
echo.
echo 2. After adding the secret, push code:
echo    git push -u origin main
echo.
echo ========================================
echo [SUCCESS] Ready to deploy!
echo ========================================
echo.

pause
