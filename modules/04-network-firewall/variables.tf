variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "firewall_policy_config" {
  type = any
}

variable "logging_config" {
  type = any
}

variable "tags" {
  type = map(string)
}
