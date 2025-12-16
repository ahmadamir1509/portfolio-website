# AWS Setup Scripts

This directory contains scripts to automate AWS setup for the CI/CD pipeline.

## Scripts Included

### 1. setup-aws.sh
Run this to set up all AWS prerequisites automatically.

### 2. get-outputs.sh
Retrieves Terraform outputs and AWS resource information.

### 3. cleanup.sh
Destroys all infrastructure when you're done testing.

---

## Quick Start

```bash
# 1. Setup AWS infrastructure
./setup-aws.sh

# 2. Deploy infrastructure with Terraform
cd terraform
terraform apply

# 3. Get outputs
../get-outputs.sh

# 4. Push code to trigger pipeline
git push origin main

# 5. View results
# Go to GitHub Actions to see the pipeline run
```
