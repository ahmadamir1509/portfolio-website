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

output "ssh_key_path" {
  value       = var.public_key_path == "" ? local_file.private_key[0].filename : "Use your own key"
  description = "Path to SSH private key (if generated)"
  sensitive   = true
}
