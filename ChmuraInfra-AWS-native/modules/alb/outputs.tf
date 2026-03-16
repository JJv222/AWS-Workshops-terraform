output "alb_dns" {
  value       = aws_lb.alb.dns_name
  description = "Public DNS of ALB"
}

output "frontend_tg_arn" {
  value       = aws_lb_target_group.frontend_tg.arn
  description = "Frontend TG ARN"
}

output "backend_tg_arn" {
  value       = aws_lb_target_group.backend_tg.arn
  description = "Backend TG ARN"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "HTTP listener ARN"
}
