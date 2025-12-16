# EC2 Instance for Portfolio Website
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.deployer.key_name

  user_data = base64encode(file("${path.module}/user_data.sh"))

  tags = {
    Name = "portfolio-website"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_iam_role_policy_attachment.ec2_s3_access
  ]
}

# Key Pair for SSH
resource "aws_key_pair" "deployer" {
  key_name   = "portfolio-deployer-key"
  public_key = var.public_key_path != "" ? file(var.public_key_path) : tls_private_key.deployer[0].public_key_openssh

  tags = {
    Name = "portfolio-deployer-key"
  }
}

# Generate private key if not provided
resource "tls_private_key" "deployer" {
  count     = var.public_key_path == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  count             = var.public_key_path == "" ? 1 : 0
  content           = tls_private_key.deployer[0].private_key_pem
  filename          = "${path.module}/../portfolio-deployer-key.pem"
  file_permission   = "0600"
  sensitive_content = true
}
