output "alb_dns" {
  value       = module.alb.alb_dns
  description = "Public DNS of the ALB"
}

output "jdbc_connection_string" {
  value       = nonsensitive(module.rds.jdbc_url)
  description = "JDBC connection string for RDS"
}