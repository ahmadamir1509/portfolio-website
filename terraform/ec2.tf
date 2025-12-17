# EC2 Instance for Portfolio Website
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.deployer.key_name

  # Use a timestamp to ensure unique key names
  user_data = base64encode(file("${path.module}/user_data.sh"))

  tags = {
    Name = "portfolio-website-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ec2_s3_access
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Generate SSH private key
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS Key Pair from generated public key
resource "aws_key_pair" "deployer" {
  key_name   = "portfolio-deployer-key-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  public_key = tls_private_key.deployer.public_key_openssh

  tags = {
    Name = "portfolio-deployer-key"
  }
}
