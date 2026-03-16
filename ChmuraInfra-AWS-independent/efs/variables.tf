variable "creation_token" {
  description = "Unikalny token do tworzenia EFS"
  type        = string
}

variable "subnet_ids" {
  description = "Lista ID subnetów, w których mają być utworzone Mount Targets"
  type        = list(string)
}

variable "security_groups" {
  description = "Lista Security Groups przypisanych do EFS"
  type        = list(string)
}
