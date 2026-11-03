variable "name_prefix" {
  type = string
}

variable "limit_amount" {
  type        = string
  description = "Monthly budget limit in USD"
  default     = "75"
}

variable "threshold_percent" {
  type    = number
  default = 80
}

variable "alert_emails" {
  type = list(string)
}
