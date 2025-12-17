# ECR Repository for Portfolio Website
resource "aws_ecr_repository" "portfolio" {
  name                 = "portfolio-website"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "portfolio-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "portfolio" {
  repository = aws_ecr_repository.portfolio.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.portfolio.repository_url
  description = "ECR Repository URL"
}

output "ecr_registry_id" {
  value       = aws_ecr_repository.portfolio.registry_id
  description = "ECR Registry ID"
}
