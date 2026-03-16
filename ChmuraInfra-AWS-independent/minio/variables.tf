variable "project_name" {}
variable "aws_region" { default = "us-east-1" }
variable "ecs_cluster_id" {}
variable "ecs_task_execution_role_arn" {}
variable "subnets" { type = list(string) }
variable "security_group_id" {}

variable "efs_file_system_id" {}

variable "minio_api_tg_arn" {}
variable "minio_console_tg_arn" {}

variable "minio_root_user" {}
variable "minio_root_password" {}

variable "efs_access_point_id" {}