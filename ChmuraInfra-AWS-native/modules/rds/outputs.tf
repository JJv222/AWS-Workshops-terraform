output "db_endpoint" {
  value       = aws_db_instance.default.endpoint
  description = "RDS Database endpoint (host:port)"
}

output "db_resource_id" {
  value       = aws_db_instance.default.resource_id
  description = "RDS Database resource ID"
}

output "jdbc_url" {
  value       = "jdbc:postgresql://${aws_db_instance.default.address}:${aws_db_instance.default.port}/${aws_db_instance.default.db_name}?user=${var.db_username}&password=${var.db_password}"
  description = "JDBC PostgreSQL URL for Spring Boot"
}
