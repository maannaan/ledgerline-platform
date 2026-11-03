terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_secretsmanager_secret" "app" {
  name       = "${var.name_prefix}/app"
  kms_key_id = var.kms_key_arn
  tags       = merge(var.tags, { Name = "${var.name_prefix}-app-secret" })
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    DATABASE_URL   = var.database_url
    ADMIN_TOKEN    = var.admin_token
    API_KEY_PEPPER = var.api_key_pepper
  })
}
