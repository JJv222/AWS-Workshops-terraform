variable "project_name"    { type = string }
variable "public_availability_zones"      { type = list(string) }
variable "backend_availability_zone"      { type = string } 
variable "vpc_cidr"        { type = string }
variable "public_subnets"  { type = list(string) }
variable "private_subnets" {
	type = list(string)
}

variable "private_availability_zones" {
	type = list(string)
}
