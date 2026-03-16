variable "project_name" {
    type        = string
    description = "Nazwa projektu"
}
variable "vpc_id" {
    type        = string
    description = "ID VPC, w której zostanie utworzony ALB"
}
variable "frontend_port" {
    type        = number
    description = "Port na którym ALB będzie nasłuchiwać ruch dla frontendu"
}
variable "backend_port" {
    type        = number
    description = "Port na którym ALB będzie nasłuchiwać ruch dla backendu"
}

variable "frontend_alb_subnets" {
    type        = list(string)
    description = "Lista ID podsieci, w których zostanie utworzony ALB"
}


variable "frontend_security_groups" {
    type        = list(string)
    description = "Lista ID security group dla frontendu ALB"
}