variable "project_name" {}
variable "aws_region" { default = "us-east-1" }
variable "ecs_cluster_id" {}
variable "ecs_task_execution_role_arn" {}
variable "subnets" { type = list(string) }
variable "security_group_id" {}
variable "efs_file_system_id" {}

variable "internal_db_dns_name" {}
variable "db_username" {}
variable "db_password" {}

variable "grafana_password" { default = "admin" }

variable "grafana_tg_arn" {}
variable "prometheus_tg_arn" {}

variable "access_point_prometheus_id" {}
variable "access_point_grafana_id" {}

variable "prometheus_repository_url" {}

variable "exporter_target_group_arn" {
  description = "ARN Target Groupy dla Postgres Exportera"
}

variable "grafana_repository_url" {}