variable "environment" {
  type = string
}

variable "tenants" {
  description = "Map of tenant_id => metadata. db_target is shared|dedicated:<name>."
  type = map(object({
    tier          = string
    region        = string
    status        = string
    db_target     = string
    kms_key_alias = string
    notes         = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
