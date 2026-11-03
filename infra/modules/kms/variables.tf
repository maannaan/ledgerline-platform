variable "alias_name" {
  type = string
}

variable "description" {
  type = string
}

variable "deletion_window_in_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
