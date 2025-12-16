output "instance_id" {
  value       = aws_instance.web.id
  description = "ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP address of the EC2 instance"
}

output "website_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "URL to access the portfolio website"
}

output "ssh_private_key" {
  value       = tls_private_key.deployer.private_key_pem
  description = "SSH private key for EC2 access"
  sensitive   = true
}
