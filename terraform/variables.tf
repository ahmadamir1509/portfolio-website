variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type (t2.micro is Free Tier eligible)"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}
