variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type (t3.micro or t2.small)"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}
