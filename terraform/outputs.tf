# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.portfolio.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.portfolio.arn
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.portfolio_cluster.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.portfolio_cluster.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.portfolio_service.name
}

output "ecs_service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.portfolio_service.id
}

# Load Balancer Outputs (if using ALB)
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = try(aws_lb.portfolio_alb.dns_name, "Not configured")
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = try(aws_lb.portfolio_alb.zone_id, "Not configured")
}

# Application URL
output "application_url" {
  description = "Application URL"
  value       = try("http://${aws_lb.portfolio_alb.dns_name}", "Configure load balancer first")
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.portfolio_task.arn
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.portfolio_task.family
}

# Security Group Outputs
output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = aws_security_group.ecs_sg.id
}

# CloudWatch Logs Output
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.portfolio_logs.name
}

# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

# IAM Role Outputs
output "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

# Current Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# Docker Image Info
output "docker_image_uri" {
  description = "Docker image URI for deployment"
  value       = "${aws_ecr_repository.portfolio.repository_url}:latest"
}

output "deployment_commands" {
  description = "Useful deployment commands"
  value = <<EOT
To deploy manually:

1. Build and push to ECR:
   docker build -t ${aws_ecr_repository.portfolio.repository_url}:latest .
   aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
   docker push ${aws_ecr_repository.portfolio.repository_url}:latest

2. Update ECS service:
   aws ecs update-service --cluster ${aws_ecs_cluster.portfolio_cluster.name} --service ${aws_ecs_service.portfolio_service.name} --force-new-deployment

3. View logs:
   aws logs tail /ecs/portfolio-task --follow
EOT
}