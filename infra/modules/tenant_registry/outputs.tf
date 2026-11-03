output "tenant_parameter_names" {
  value = { for k, p in aws_ssm_parameter.tenant : k => p.name }
}

output "tenant_inventory" {
  value = {
    for k, v in var.tenants : k => {
      tier      = v.tier
      db_target = v.db_target
      status    = v.status
      region    = v.region
    }
  }
}
