variable "aws_region"   { 
    type = string 
    default = "us-east-1"
}
variable "availability_zones" {
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}
variable "project_name" { 
    type = string 
    default = "my-terraform-project"
}

variable "vpc_cidr"        { type = string }
variable "public_subnets"  { type = list(string) }
variable "private_subnets" { type = list(string) }

# Fargate variables
variable "frontend_port" {
  type        = number
}

variable "backend_port" {
  type        = number
}

variable "frontend_replicas" {
  type        = number
}

variable "backend_replicas" {
  type= number
  }

# RDS variables
variable "db_name" {
  type        = string
  default     = "notepad"
}

variable "db_username" {
  type        = string
  default     = "postgres"
}

variable "db_password" {
  type        = string
  sensitive   = true
}
variable "db_port" {
  type        = number
  default     = 5432
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN istniejącej roli ECS Task Execution (np. arn:aws:iam::ACCOUNT_ID:role/LabRole)"
}