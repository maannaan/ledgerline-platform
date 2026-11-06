output "alb_dns_name" {
  value = module.ecs_api.alb_dns_name
}

output "ecr_repository_url" {
  value = module.ecs_api.ecr_repository_url
}

output "shared_db_endpoint" {
  value = module.shared_db.db_endpoint
}

output "dedicated_db_endpoints" {
  value = { for k, m in module.dedicated_db : k => m.db_endpoint }
}

output "tenant_inventory" {
  value = module.tenant_registry.tenant_inventory
}

output "app_secret_arn" {
  value = module.secrets.secret_arn
}

output "gha_role_arn" {
  value       = module.github_oidc.gha_role_arn
  description = "OIDC role for GitHub Actions (commit into .github/workflows/aws-role-arns.json after apply)."
}

output "ci_secret_name" {
  value = module.github_oidc.ci_secret_name
}
