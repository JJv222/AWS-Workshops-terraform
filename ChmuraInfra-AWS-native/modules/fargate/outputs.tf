output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Nazwa ECS Cluster"
}

output "frontend_service_name" {
  value       = aws_ecs_service.frontend.name
  description = "Nazwa Frontend ECS Service"
}

output "backend_service_name" {
  value       = aws_ecs_service.backend.name
  description = "Nazwa Backend ECS Service"
}

output "cloudwatch_log_group" {
  value       = aws_cloudwatch_log_group.ecs.name
  description = "CloudWatch Log Group dla ECS logs"
}
