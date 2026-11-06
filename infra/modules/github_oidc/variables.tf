variable "name_prefix" {
  type        = string
  description = "e.g. ll-staging"
}

variable "aws_region" {
  type = string
}

variable "github_org_repo" {
  type        = string
  description = "GitHub org/repo for OIDC subject, e.g. maannaan/ledgerline-platform"
  default     = "maannaan/ledgerline-platform"
}

variable "manage_oidc_provider" {
  type        = bool
  description = "Create the account OIDC provider (once per AWS account). Other envs set false and look it up."
  default     = true
}

variable "ecr_repository_arn" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "alb_smoke_url" {
  type        = string
  description = "Optional base URL for post-deploy smoke (stored in ASM ci secret)"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
