resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.frontend_security_groups
  subnets            = var.frontend_alb_subnets

  tags = {
    Environment = "public-alb"
  }
}

# TG dla frontu
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path    = "/"
    matcher = "200"
  }
}

# TG dla backendu
resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/api" 
    matcher = "401"
  }
}

# Listener publiczny (domyślnie -> front)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.frontend_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# Rule: /api/* -> backend
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern { values = ["/api/*"] }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}
