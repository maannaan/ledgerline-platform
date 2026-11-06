terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  oidc_url = "token.actions.githubusercontent.com"
  # GitHub Actions OIDC CA thumbprint (AWS also validates the cert chain).
  oidc_thumbprints = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  ci_secret_name   = "${var.name_prefix}/ci"
  role_name        = "${var.name_prefix}-gha"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.manage_oidc_provider ? 1 : 0

  url             = "https://${local.oidc_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.oidc_thumbprints
  tags            = merge(var.tags, { Name = "github-actions-oidc" })
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.manage_oidc_provider ? 0 : 1
  url   = "https://${local.oidc_url}"
}

locals {
  oidc_provider_arn = var.manage_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

data "aws_iam_policy_document" "gha_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_url}:sub"
      values   = ["repo:${var.github_org_repo}:*"]
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  tags               = merge(var.tags, { Name = local.role_name })
}

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid    = "EcrAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid    = "EcsDeploy"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeClusters",
      "ecs:ListServices"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassTaskRoles"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      var.ecs_execution_role_arn,
      var.ecs_task_role_arn
    ]
  }

  statement {
    sid    = "CiSecretRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.ci.arn
    ]
  }

  statement {
    sid    = "CiSecretKms"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "gha" {
  name   = "${local.role_name}-policy"
  role   = aws_iam_role.gha.id
  policy = data.aws_iam_policy_document.gha_permissions.json
}

resource "aws_secretsmanager_secret" "ci" {
  name       = local.ci_secret_name
  kms_key_id = var.kms_key_arn
  tags       = merge(var.tags, { Name = "${var.name_prefix}-ci-secret" })
}

# Placeholder values — replace SONAR_TOKEN out-of-band (never commit real tokens).
resource "aws_secretsmanager_secret_version" "ci" {
  secret_id = aws_secretsmanager_secret.ci.id
  secret_string = jsonencode({
    SONAR_TOKEN   = "REPLACE_ME"
    ALB_SMOKE_URL = var.alb_smoke_url
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
