variable "transit_gateway_name" {
  type = string
}

variable "target_vpc_id" {
  type = string
}

variable "target_subnet_ids" {
  type = list(string)
}

variable "target_route_table_ids" {
  type = list(string)
}

variable "target_account_id" {
  type = list(string)
}

variable "source_vpc_id" {
  type = string
}

variable "source_subnet_ids" {
  type = list(string)
}

variable "source_cidr_block" {
  type = string
}

variable "tags" {
  type = map(string)
}
