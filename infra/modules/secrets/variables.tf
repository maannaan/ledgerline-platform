variable "name_prefix" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "admin_token" {
  type      = string
  sensitive = true
}

variable "api_key_pepper" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
