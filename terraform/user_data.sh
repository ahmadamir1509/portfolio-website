#!/bin/bash

echo "=== Portfolio Flask Website EC2 Setup ===" | tee /tmp/setup.log

# Update system
yum update -y 2>&1 | tee -a /tmp/setup.log

# Install Python and pip
yum install -y python3 python3-pip git 2>&1 | tee -a /tmp/setup.log

# Create app directory
mkdir -p /home/ec2-user/portfolio
cd /home/ec2-user/portfolio

# Clone the latest code
echo "Cloning repository..." | tee -a /tmp/setup.log
git clone https://github.com/ahmadamir1509/portfolio-website.git . 2>&1 | tee -a /tmp/setup.log || git pull 2>&1 | tee -a /tmp/setup.log

# Install Python dependencies
echo "Installing dependencies..." | tee -a /tmp/setup.log
pip3 install -r requirements.txt 2>&1 | tee -a /tmp/setup.log

# Change ownership
chown -R ec2-user:ec2-user /home/ec2-user/portfolio

# Start Flask in background with proper logging
echo "Starting Flask..." | tee -a /tmp/setup.log
cd /home/ec2-user/portfolio
su - ec2-user -c "cd /home/ec2-user/portfolio && nohup python3 app.py > /tmp/flask.log 2>&1 &" 2>&1 | tee -a /tmp/setup.log

echo "=== Setup complete ===" | tee -a /tmp/setup.log
sleep 5
ps aux | grep app.py | grep -v grep | tee -a /tmp/setup.log


    cp -r /tmp/website/* /var/www/html/ 2>/dev/null || true
fi

# Create default index.html if not provided
if [ ! -f /var/www/html/index.html ]; then
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Portfolio - Ahmad Amir</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.95);
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            text-align: center;
            max-width: 600px;
        }
        h1 { color: #333; margin: 0 0 10px 0; }
        p { color: #666; line-height: 1.6; }
        .status { color: #667eea; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✨ Portfolio Website</h1>
        <p>Welcome to my portfolio!</p>
        <p class="status">Website is LIVE and running on EC2</p>
        <p>Deployed with Terraform + GitHub Actions + Apache</p>
    </div>
</body>
</html>
EOF
fi

echo "=== Apache Setup Complete ==="
echo "Website directory: /var/www/html/"
echo "Apache is running and ready to serve content"
docker rm portfolio-website 2>/dev/null || true

# Run new container
docker run -d \
  --name portfolio-website \
  --restart always \
  -p 80:5000 \
  -e FLASK_ENV=production \
  $ECR_REPOSITORY_URL:latest

# Wait for container to be healthy
sleep 5

# Clean up dangling images
docker image prune -f --filter "dangling=true"
DEPLOY_SCRIPT

chmod +x /home/ec2-user/deploy.sh

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker",
            "log_group_name": "/aws/ec2/portfolio-website",
            "log_stream_name": "docker-logs"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_USAGE_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
