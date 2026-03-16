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

# ======================================================
# 1. APP (Frontend + Backend) - PORT 80
# ======================================================

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

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/actuator/health"
    matcher = "200,401"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.frontend_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern { values = ["/api/*", "/actuator/*"] }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# ======================================================
# 2. KEYCLOAK - PORT 8081
# ======================================================

resource "aws_lb_target_group" "keycloak_tg" {
  name        = "${var.project_name}-keycloak-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/health"
    matcher = "200-404"
  }
}

resource "aws_lb_listener" "keycloak" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.keycloak_port # (8081)
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_tg.arn
  }
}

# ======================================================
# 3. MINIO API - PORT 9000
# ======================================================

resource "aws_lb_target_group" "minio_api_tg" {
  name        = "${var.project_name}-minio-api-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/minio/health/live"
    matcher = "200-404"
  }
}

resource "aws_lb_listener" "minio_api" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.minio_api_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minio_api_tg.arn
  }
}

# ======================================================
# 4. MINIO CONSOLE - PORT 9001
# ======================================================

resource "aws_lb_target_group" "minio_console_tg" {
  name        = "${var.project_name}-minio-ui-tg"
  port        = 9001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/minio/health/live"
    matcher = "200-404"
  }
}

resource "aws_lb_listener" "minio_console" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.minio_console_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minio_console_tg.arn
  }
}


# ======================================================
# 4. GRAFANA & PROMETHEUS 
# ======================================================

resource "aws_lb_target_group" "grafana" {
  name        = "${var.project_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/api/health"
    matcher = "200"
  }
}

resource "aws_lb_target_group" "prometheus" {
  name        = "${var.project_name}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/-/healthy"
    matcher = "200"
  }
}

# --- Listeners ---

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "9090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}