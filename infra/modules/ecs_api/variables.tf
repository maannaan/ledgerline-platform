variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "app_secret_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "container_image" {
  type        = string
  description = "Optional explicit image URI. Empty uses ECR repo :latest."
  default     = ""
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "enable_container_insights" {
  type    = bool
  default = false
}

variable "acm_certificate_arn" {
  type        = string
  description = "Optional ACM cert ARN in this region. When set, ALB serves HTTPS:443 and HTTP redirects to HTTPS."
  default     = null
  nullable    = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
