variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }

# KLASTER (Przychodzi z głównego main.tf)
variable "ecs_cluster_id" {
  description = "ID istniejącego klastra ECS"
}

variable "ecs_task_execution_role_arn" {}

variable "frontend_image" {}
variable "backend_image" {}

variable "frontend_port" { default = 80 }
variable "backend_port" { default = 8080 }

variable "frontend_tg_arn" {}
variable "backend_tg_arn" {}

variable "frontend_sg_id" {}
variable "backend_sg_id" {}

variable "alb_dns_name" {
  description = "Publiczny DNS Load Balancera (dla Keycloak i MinIO)"
}

variable "internal_db_dns_name" {
  description = "Wewnętrzny DNS Load Balancera Bazy Danych"
}

variable "db_username" {}
variable "db_password" {}

variable "minio_access_key" { default = "minioadmin" }
variable "minio_secret_key" { default = "superTajneHaslo" }
variable "minio_bucket" { default = "simplenotatnik" }

variable "backend_url" {
  description = "Publiczny URL backendu (API)"
}