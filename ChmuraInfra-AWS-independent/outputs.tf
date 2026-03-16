output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Public DNS of the ALB"
}

output "app_url" {
  value = "http://${module.alb.alb_dns_name}"
}
output "keycloak_url" {
  value = "http://${module.alb.alb_dns_name}:8081"
}
output "minio_console_url" {
  value = "http://${module.alb.alb_dns_name}:9001"
}

output "grafana_url" {
  value = "http://${module.alb.alb_dns_name}:3000"
}

output "prometheus_url" {
  value = "http://${module.alb.alb_dns_name}:9090"
}

output "internal-nlb" {
  value       = aws_lb.internal_db.dns_name
  description = "Internal NLB DNS name for RDS"
}
