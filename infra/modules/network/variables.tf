variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "Who may reach the ALB. Restrict in production."
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
