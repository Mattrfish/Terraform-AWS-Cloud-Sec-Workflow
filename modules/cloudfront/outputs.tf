output cloudfront_domain_name{
    value       = aws_cloudfront_distribution.s3_distribution.domain_name
    description = "The domain name of the cloudfront distribution"
}

output cloudfront_id{
    value       = aws_cloudfront_distribution.s3_distribution.id
    description = "The id of the cloudfront distribution"
}

output "cloudfront_arn" {
  value       = aws_cloudfront_distribution.s3_distribution.arn
  description = "The ARN of the cloudfront distribution"
}