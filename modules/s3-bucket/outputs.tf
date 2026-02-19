output "bucket_arn"{
    value       = aws_s3_bucket.my_bucket.arn
    description = "The ARN of the bucket"
}

output "bucket_id" {
    value       = aws_s3_bucket.my_bucket.id
    description = "The ID of the bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.my_bucket.bucket_regional_domain_name
  description = "The regional domain name of the bucket"
}