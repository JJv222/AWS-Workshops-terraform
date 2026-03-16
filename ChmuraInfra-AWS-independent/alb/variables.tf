variable "project_name" {
  type        = string
  description = "Nazwa projektu"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC"
}

variable "frontend_port" {
  type        = number
  description = "Port HTTP aplikacji (zazwyczaj 80)"
  default     = 80
}

variable "backend_port" {
  type        = number
  description = "Port wewnętrzny backendu (np. 8080)"
  default     = 8080
}

variable "keycloak_port" {
  type        = number
  description = "Port publiczny dla Keycloaka"
  default     = 8081
}

variable "minio_api_port" {
  type        = number
  description = "Port API MinIO"
  default     = 9000
}

variable "minio_console_port" {
  type        = number
  description = "Port Konsoli MinIO"
  default     = 9001
}

variable "frontend_alb_subnets" {
  type        = list(string)
  description = "Subnety publiczne dla ALB"
}

variable "frontend_security_groups" {
  type        = list(string)
  description = "Lista Security Groups dla ALB"
}