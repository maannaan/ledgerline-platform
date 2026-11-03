# Production uses the same modules as staging with stricter defaults.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "ll-${var.environment}"
  common_tags = {
    Project     = "ledgerline"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tenants = merge(
    {
      for t in var.shared_tenants : t => {
        tier          = "shared"
        region        = var.aws_region
        status        = "active"
        db_target     = "shared"
        kms_key_alias = "alias/${local.name_prefix}-shared"
        notes         = "Pooled shared RDS"
      }
    },
    {
      for t, cfg in var.dedicated_tenants : t => {
        tier          = "dedicated"
        region        = var.aws_region
        status        = "active"
        db_target     = "dedicated:${t}"
        kms_key_alias = "alias/${local.name_prefix}-${t}"
        notes         = cfg.notes
      }
    }
  )
}

resource "random_password" "admin_token" {
  length  = 48
  special = false
}

resource "random_password" "api_key_pepper" {
  length  = 48
  special = false
}

module "network" {
  source            = "../../modules/network"
  name_prefix       = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  alb_ingress_cidrs = var.alb_ingress_cidrs
  tags              = local.common_tags
}

module "shared_kms" {
  source      = "../../modules/kms"
  alias_name  = "${local.name_prefix}-shared"
  description = "Ledgerline shared platform encryption key (${var.environment})"
  tags        = local.common_tags
}

module "shared_db" {
  source                  = "../../modules/rds"
  name_prefix             = "${local.name_prefix}-shared"
  subnet_ids              = module.network.public_subnet_ids
  security_group_id       = module.network.db_security_group_id
  kms_key_arn             = module.shared_kms.key_arn
  instance_class          = var.db_instance_class
  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = !var.deletion_protection
  tenant_tier             = "shared"
  tags                    = local.common_tags
}

module "dedicated_kms" {
  for_each    = var.dedicated_tenants
  source      = "../../modules/kms"
  alias_name  = "${local.name_prefix}-${each.key}"
  description = "Dedicated KMS key for tenant ${each.key} (${var.environment})"
  tags        = merge(local.common_tags, { TenantId = each.key, TenantTier = "dedicated" })
}

module "dedicated_db" {
  for_each                = var.dedicated_tenants
  source                  = "../../modules/rds"
  name_prefix             = "${local.name_prefix}-${each.key}"
  subnet_ids              = module.network.public_subnet_ids
  security_group_id       = module.network.db_security_group_id
  kms_key_arn             = module.dedicated_kms[each.key].key_arn
  instance_class          = each.value.instance_class
  backup_retention_period = each.value.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = !var.deletion_protection
  tenant_tier             = "dedicated"
  tags                    = merge(local.common_tags, { TenantId = each.key, TenantTier = "dedicated" })
}

module "secrets" {
  source         = "../../modules/secrets"
  name_prefix    = local.name_prefix
  kms_key_arn    = module.shared_kms.key_arn
  database_url   = module.shared_db.connection_url
  admin_token    = random_password.admin_token.result
  api_key_pepper = random_password.api_key_pepper.result
  tags           = local.common_tags
}

module "ecs_api" {
  source                = "../../modules/ecs_api"
  name_prefix           = local.name_prefix
  aws_region            = var.aws_region
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  app_security_group_id = module.network.app_security_group_id
  app_secret_arn        = module.secrets.secret_arn
  kms_key_arn           = module.shared_kms.key_arn
  container_image       = var.container_image
  desired_count         = var.api_desired_count
  acm_certificate_arn   = var.acm_certificate_arn
  tags                  = local.common_tags
}

module "tenant_registry" {
  source      = "../../modules/tenant_registry"
  environment = var.environment
  tenants     = local.tenants
  tags        = local.common_tags
}

module "budget" {
  count             = length(var.budget_alert_emails) > 0 ? 1 : 0
  source            = "../../modules/budget"
  name_prefix       = local.name_prefix
  limit_amount      = var.budget_limit_usd
  threshold_percent = 50
  alert_emails      = var.budget_alert_emails
}
