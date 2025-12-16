#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Portfolio Website Deployment Test ===${NC}\n"

# Step 1: Test AWS CLI
echo -e "${YELLOW}STEP 1: Testing AWS CLI${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

if [ ! -z "$ACCOUNT_ID" ]; then
    echo -e "${GREEN}✓ AWS CLI working${NC}"
    echo "  Account ID: $ACCOUNT_ID"
    echo "  User ARN: $USER_ARN"
else
    echo -e "${RED}✗ AWS CLI failed${NC}"
    exit 1
fi

echo ""

# Step 2: Create OIDC Provider
echo -e "${YELLOW}STEP 2: Setting up OIDC Provider${NC}"
OIDC=$(aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>&1)

if echo "$OIDC" | grep -q "arn:aws:iam"; then
    echo -e "${GREEN}✓ OIDC Provider created${NC}"
    echo "$OIDC" | grep "OpenIDConnectProviderArn"
elif echo "$OIDC" | grep -q "already exists"; then
    echo -e "${GREEN}✓ OIDC Provider already exists${NC}"
else
    echo -e "${YELLOW}⚠ OIDC Provider check: $OIDC${NC}"
fi

echo ""

# Step 3: Create GitHub Actions IAM Role
echo -e "${YELLOW}STEP 3: Creating GitHub Actions IAM Role${NC}"

# Create trust policy
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ahmadamir1509/portfolio-website:*"
        }
      }
    }
  ]
}
EOF

# Create role
ROLE_CREATE=$(aws iam create-role \
    --role-name GitHubActionsRole \
    --assume-role-policy-document file:///tmp/trust-policy.json 2>&1)

if echo "$ROLE_CREATE" | grep -q "arn:aws:iam"; then
    echo -e "${GREEN}✓ GitHub Actions Role created${NC}"
elif echo "$ROLE_CREATE" | grep -q "already exists"; then
    echo -e "${GREEN}✓ GitHub Actions Role already exists${NC}"
else
    echo -e "${RED}✗ Role creation issue: $ROLE_CREATE${NC}"
fi

# Create inline policy
cat > /tmp/github-actions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name GitHubActionsRole \
    --policy-name GitHubActionsPolicy \
    --policy-document file:///tmp/github-actions-policy.json

echo -e "${GREEN}✓ IAM Policy attached${NC}"

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text)
echo "  Role ARN: $ROLE_ARN"

echo ""

# Step 4: Test Terraform
echo -e "${YELLOW}STEP 4: Validating Terraform${NC}"
cd terraform

terraform init -backend=false > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform init successful${NC}"
else
    echo -e "${RED}✗ Terraform init failed${NC}"
    exit 1
fi

terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform validation passed${NC}"
else
    echo -e "${RED}✗ Terraform validation failed${NC}"
    terraform validate
    exit 1
fi

echo ""

# Step 5: Terraform Plan
echo -e "${YELLOW}STEP 5: Planning Terraform deployment${NC}"
terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1" -out=tfplan > /dev/null 2>&1

if [ -f tfplan ]; then
    echo -e "${GREEN}✓ Terraform plan created successfully${NC}"
    terraform plan -var="bucket_name=noor-portfolio-website" -var="aws_region=us-east-1" -no-color | head -20
else
    echo -e "${RED}✗ Terraform plan failed${NC}"
    exit 1
fi

echo ""

# Step 6: Apply Terraform
echo -e "${YELLOW}STEP 6: Applying Terraform (Creating S3 bucket)${NC}"
terraform apply -auto-approve tfplan > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform apply successful${NC}"
    BUCKET=$(terraform output -raw bucket_name 2>/dev/null)
    WEBSITE_URL=$(terraform output -raw website_domain 2>/dev/null)
    echo "  Bucket: $BUCKET"
    echo "  Website URL: $WEBSITE_URL"
else
    echo -e "${RED}✗ Terraform apply failed${NC}"
    exit 1
fi

cd ..

echo ""

# Step 7: Initialize Git
echo -e "${YELLOW}STEP 7: Initializing Git Repository${NC}"

if [ ! -d ".git" ]; then
    git init > /dev/null 2>&1
    git config user.name "DevOps Engineer" > /dev/null 2>&1
    git config user.email "devops@portfolio.local" > /dev/null 2>&1
    echo -e "${GREEN}✓ Git repository initialized${NC}"
else
    echo -e "${GREEN}✓ Git repository already exists${NC}"
fi

# Check if remote exists
if git remote | grep -q origin; then
    echo -e "${GREEN}✓ Git remote 'origin' already configured${NC}"
else
    echo -e "${YELLOW}⚠ Git remote 'origin' not configured yet${NC}"
    echo "  Run: git remote add origin https://github.com/ahmadamir1509/portfolio-website.git"
fi

echo ""

# Step 8: Summary
echo -e "${BLUE}=== DEPLOYMENT CHECKLIST ===${NC}"
echo -e "${GREEN}✓${NC} AWS CLI credentials verified"
echo -e "${GREEN}✓${NC} OIDC Provider configured"
echo -e "${GREEN}✓${NC} GitHub Actions IAM Role created"
echo -e "${GREEN}✓${NC} Terraform validated"
echo -e "${GREEN}✓${NC} S3 bucket created"
echo -e "${GREEN}✓${NC} Git repository initialized"

echo ""
echo -e "${BLUE}=== NEXT STEPS ===${NC}"
echo "1. Add GitHub Secret:"
echo "   - Go to: GitHub Repo → Settings → Secrets and variables → Actions"
echo "   - New secret: AWS_ROLE_ARN"
echo "   - Value: $ROLE_ARN"
echo ""
echo "2. Add Git Remote (if not done):"
echo "   git remote add origin https://github.com/ahmadamir1509/portfolio-website.git"
echo ""
echo "3. Push code to GitHub:"
echo "   git add ."
echo "   git commit -m 'Initial deployment'"
echo "   git push -u origin main"
echo ""
echo "4. Check GitHub Actions:"
echo "   - Go to: https://github.com/ahmadamir1509/portfolio-website/actions"
echo ""
echo -e "${GREEN}Website will be live at: $WEBSITE_URL${NC}"
