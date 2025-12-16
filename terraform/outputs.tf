output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "website_url" {
  description = "Website URL"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "website_domain" {
  description = "Website domain"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
