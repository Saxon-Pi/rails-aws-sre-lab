output "ecr_repository_url" {
  value = aws_ecr_repository.rails_app.repository_url
}

output "kiro_discovery_role_arn" {
  description = "IAM Role ARN used by Kiro Web for AWS discovery"
  value       = aws_iam_role.kiro_discovery.arn
}