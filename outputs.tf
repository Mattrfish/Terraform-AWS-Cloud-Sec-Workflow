output "website_url" {
  description = "The secure URL of the website"
  # reference the module name used in main.tf (secure_cdn)
  value       = module.secure_cdn.cloudfront_domain_name
}

output "github_actions_role_arn" {
  description = "The ARN of the role for GitHub Actions to assume"
  value = aws_iam_role.aws_oidc_role.arn
}