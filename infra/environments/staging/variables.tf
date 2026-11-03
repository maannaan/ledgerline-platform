variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "Restrict ALB source IPs when possible."
  default     = ["0.0.0.0/0"]
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "api_desired_count" {
  type    = number
  default = 1
}

variable "container_image" {
  type    = string
  default = ""
}

variable "shared_tenants" {
  type    = list(string)
  default = ["acme", "brightpath", "cobalt", "harbor"]
}

variable "dedicated_tenants" {
  type = map(object({
    notes                 = string
    instance_class        = optional(string, "db.t4g.micro")
    backup_retention_days = optional(number, 7)
  }))
  default = {
    delta = {
      notes                 = "Delta Finance — dedicated DB + KMS key + admin audit"
      instance_class        = "db.t4g.micro"
      backup_retention_days = 7
    }
  }
}

variable "budget_limit_usd" {
  type    = string
  default = "75"
}

variable "budget_alert_emails" {
  type        = list(string)
  description = "Set before apply so AWS Budgets can email. Empty skips budget module."
  default     = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "Optional ACM certificate ARN (ap-south-1). Enables HTTPS listener + HTTP→HTTPS redirect."
  default     = null
  nullable    = true
}
