output "ci_cd_role_arn" {
  description = "The ARN of the CI/CD role to be assumed by GitHub Actions via OIDC."
  value       = aws_iam_role.ci_cd_role.arn
}
