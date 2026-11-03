variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_backup_retention_days" {
  type    = number
  default = 14
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "api_desired_count" {
  type    = number
  default = 2
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
    backup_retention_days = optional(number, 14)
  }))
  default = {
    delta = {
      notes                 = "Delta Finance — dedicated DB + KMS key + admin audit"
      instance_class        = "db.t4g.micro"
      backup_retention_days = 14
    }
  }
}

variable "budget_limit_usd" {
  type    = string
  default = "75"
}

variable "budget_alert_emails" {
  type    = list(string)
  default = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "Optional ACM certificate ARN. Enables HTTPS listener + HTTP→HTTPS redirect."
  default     = null
  nullable    = true
}
