variable "project_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "db_allocated_storage" {
  type    = number
  default = 100
}
variable "db_username" {
  type = string
}
variable "db_password" {
  type = string
}
variable "private_subnets_ids" {
  type = list(string)
}
variable "security_group_id" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}