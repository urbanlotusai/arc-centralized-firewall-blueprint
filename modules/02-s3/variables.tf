variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "kms_master_key_id" {
  type = string
}

variable "lifecycle_configuration_rules" {
  type = any
}

variable "tags" {
  type = map(string)
}
