variable "project_name" {
  type        = string
  description = "Nazwa projektu"
}

variable "vpc_id" {
  type        = string
  description = "ID sieci VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Lista ID publicznych podsieci dla Load Balancera"
}

variable "s3_name" {
  type        = string
  description = "Nazwa istniejącego bucketu S3 do przechowywania plików statycznych frontend"
}

variable "connection_string" {
  type        = string
  description = "Łańcuch połączenia do bazy danych RDS PostgreSQL"
}
variable "db_username" {
  type        = string
  description = "Nazwa użytkownika bazy danych RDS PostgreSQL"
}
variable "db_password" {
  type        = string
  description = "Hasło użytkownika bazy danych RDS PostgreSQL"
}

variable "frontend_image" {
  type        = string
  description = "Docker image URI dla frontend (np. 123456789.dkr.ecr.us-east-1.amazonaws.com/frontend:latest)"
}

variable "backend_image" {
  type        = string
  description = "Docker image URI dla backend (np. 123456789.dkr.ecr.us-east-1.amazonaws.com/backend:latest)"
}

variable "frontend_port" {
  type        = number
  description = "Port na którym nasłuchuje frontend"
}

variable "backend_port" {
  type        = number
  description = "Port na którym nasłuchuje backend"
}

variable "frontend_tg_arn" {
  type        = string
  description = "ARN TG dla frontend"
}

variable "backend_tg_arn" {
  type        = string
  description = "ARN TG dla backend"
}

variable "backend_sg_id" {
  type        = string
  description = "SG dla backend tasków"
}


variable "backend_url" {
  type        = string
  description = "URL dostępu do backendu (np. http://backend-alb-dns-name:backend_port/api)"
}

variable "frontend_sg_id"{
  type        = string
  description = "ID security group dla frontend Fargate"
}

# RDS variables dla backendu

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN istniejącej roli ECS Task Execution (np. arn:aws:iam::ACCOUNT_ID:role/LabRole)"
}

# Cognito dla frontendu
variable "cognit_issuer_url" {
  type        = string
}
variable "cognito_client_id" {
  type        = string
}
variable "cognito_scopes" {
  type        = list(string)
  default = ["openid", "email", "phone"]
}
variable "cognito_redirect_url" {
  type        = string
}
variable "cognito_logout_url" {
  type        = string
}