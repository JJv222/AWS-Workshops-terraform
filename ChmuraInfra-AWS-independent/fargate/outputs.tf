
output "frontend_service_name" {
  value       = aws_ecs_service.frontend.name
  description = "Nazwa Frontend ECS Service"
}

output "backend_service_name" {
  value       = aws_ecs_service.backend.name
  description = "Nazwa Backend ECS Service"
}
