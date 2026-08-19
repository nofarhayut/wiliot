output "repository_urls" {
  description = "Map of repository name => URL"
  value       = { for k, r in aws_ecr_repository.repo : k => r.repository_url }
}

output "repository_arns" {
  description = "Map of repository name => ARN"
  value       = { for k, r in aws_ecr_repository.repo : k => r.arn }
}
