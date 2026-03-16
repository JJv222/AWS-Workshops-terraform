variable "project_name" {}
variable "aws_region" { default = "us-east-1" }

variable "ecs_cluster_id" {}
variable "ecs_task_execution_role_arn" {}

variable "subnets" { type = list(string) }
variable "security_group_id" {}

variable "keycloak_image_url" {
  description = "URL obrazu z ECR lub quay.io/keycloak/keycloak:latest"
}

variable "public_alb_dns_name" {
  description = "DNS Publicznego ALB (dla KC_HOSTNAME)"
}
variable "internal_db_dns_name" {
  description = "DNS Wewnętrznego NLB (dla połączenia z bazą)"
}
variable "alb_target_group_arn" {
  description = "ARN Target Groupy z ALB dla Keycloaka"
}

variable "db_username" {}
variable "db_password" {}
variable "admin_username" { default = "admin" }
variable "admin_password" { default = "admin" }