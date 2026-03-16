output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Public DNS of ALB"
}

output "alb_arn" {
  value       = aws_lb.alb.arn
  description = "ARN of the ALB"
}

# --- Target Groups ARNs ---

output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "backend_tg_arn" {
  value = aws_lb_target_group.backend_tg.arn
}

output "keycloak_tg_arn" {
  value = aws_lb_target_group.keycloak_tg.arn
}

output "minio_api_tg_arn" {
  value = aws_lb_target_group.minio_api_tg.arn
}

output "minio_console_tg_arn" {
  value = aws_lb_target_group.minio_console_tg.arn
}

output "grafana_tg_arn" { 
  value = aws_lb_target_group.grafana.arn 
}

output "prometheus_tg_arn" {
   value = aws_lb_target_group.prometheus.arn 
}