#!/bin/bash

# Complete deployment fix - all in one script
# This directly executes all necessary fixes

INSTANCE_IP="98.93.75.181"
EC2_USER="ec2-user"
SSH_KEY="ec2-key-temp.pem"
AWS_REGION="us-east-1"

echo "======================================"
echo "AUTOMATED DEPLOYMENT FIX"
echo "======================================"
echo ""

# Step 1: Upload the fix script
echo "[1/4] Uploading deployment fix script..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    fix_deployment.sh "$EC2_USER@$INSTANCE_IP:~/fix_deployment.sh" 2>/dev/null || \
    echo "ERROR: Failed to upload script"

# Step 2: Execute the fix script on EC2
echo "[2/4] Running deployment fix on EC2..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=30 \
    "$EC2_USER@$INSTANCE_IP" \
    "bash ~/fix_deployment.sh" 2>/dev/null || \
    echo "ERROR: Failed to execute fix script"

# Step 3: Verify website is responding
echo "[3/4] Verifying website is responding..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$EC2_USER@$INSTANCE_IP" \
    "curl -s http://localhost:5000 | head -c 50" 2>/dev/null && \
    echo "" || \
    echo "Website not responding yet..."

# Step 4: Run diagnostics
echo "[4/4] Running diagnostics..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    diagnose_deployment.sh "$EC2_USER@$INSTANCE_IP:~/diagnose_deployment.sh" 2>/dev/null

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$EC2_USER@$INSTANCE_IP" \
    "bash ~/diagnose_deployment.sh" 2>/dev/null || \
    echo "Diagnostics completed"

echo ""
echo "======================================"
echo "FIX COMPLETE!"
echo "======================================"
echo ""
echo "Your website should now be updated!"
echo "Check: http://98.93.75.181:5000"
echo ""
