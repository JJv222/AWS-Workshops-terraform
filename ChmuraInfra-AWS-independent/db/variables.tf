variable "project_name" {}
variable "aws_region" { default = "us-east-1" }

variable "ecs_cluster_id" {
  description = "ID Klastra ECS"
}

variable "ecs_task_execution_role_arn" {
  description = "ARN roli IAM dla ECS"
}

variable "subnets" {
  description = "Lista subnetów, gdzie stanie baza"
  type        = list(string)
}

variable "security_group_id" {
  description = "Wspólna grupa bezpieczeństwa (ecs_tasks_sg)"
}

variable "efs_file_system_id" {
  description = "ID systemu plików EFS"
}

variable "efs_access_point_id" {
  description = "ID Access Pointa EFS"
}


variable "db_target_group_arn" {
  description = "ARN Target Groupy z wewnętrznego NLB"
}

variable "db_username" {}
variable "db_password" {}