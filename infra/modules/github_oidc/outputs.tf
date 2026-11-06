output "gha_role_arn" {
  value = aws_iam_role.gha.arn
}

output "gha_role_name" {
  value = aws_iam_role.gha.name
}

output "ci_secret_arn" {
  value = aws_secretsmanager_secret.ci.arn
}

output "ci_secret_name" {
  value = aws_secretsmanager_secret.ci.name
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}
