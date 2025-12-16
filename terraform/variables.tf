variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type (t2.micro is free tier eligible)"
}

variable "public_key_path" {
  type        = string
  default     = ""
  description = "Path to public SSH key (leave empty to generate)"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}
