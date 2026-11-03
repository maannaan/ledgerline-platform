terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Server-side tenant inventory (not caller-controlled). Used by ops/onboarding.
resource "aws_ssm_parameter" "tenant" {
  for_each = var.tenants

  name = "/ledgerline/${var.environment}/tenants/${each.key}"
  type = "String"
  value = jsonencode({
    tenant_id     = each.key
    tier          = each.value.tier
    region        = each.value.region
    status        = each.value.status
    db_target     = each.value.db_target
    kms_key_alias = each.value.kms_key_alias
    notes         = each.value.notes
  })
  tags = merge(var.tags, {
    TenantId   = each.key
    TenantTier = each.value.tier
  })
}
