# ==============================================================================
# LOGI (CloudWatch)
# ==============================================================================
resource "aws_cloudwatch_log_group" "keycloak_logs" {
  name              = "/ecs/${var.project_name}-keycloak"
  retention_in_days = 7
}

# ==============================================================================
# TASK DEFINITION
# ==============================================================================
resource "aws_ecs_task_definition" "keycloak" {
  family                   = "${var.project_name}-keycloak"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024 # 1 vCPU
  memory                   = 2048 # 2 GB RAM

  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "keycloak"
    image     = var.keycloak_image_url 
    essential = true
    
    command   = ["start-dev"] 
    
    portMappings = [
      { containerPort = 8080, protocol = "tcp" },
      { containerPort = 9000, protocol = "tcp" }
    ]
    
    environment = [
      { name = "KC_HOSTNAME",      value = var.public_alb_dns_name },
      { name = "KC_HOSTNAME_PORT", value = "8081" },

      { name = "KC_DB",          value = "postgres" },
      { name = "KC_DB_URL",      value = "jdbc:postgresql://${var.internal_db_dns_name}:5432/postgres" },
      { name = "KC_DB_USERNAME", value = var.db_username },
      { name = "KC_DB_PASSWORD", value = var.db_password },
      { name = "KC_METRICS_ENABLED", value = "true" },

      { name = "KC_BOOTSTRAP_ADMIN_USERNAME", value = var.admin_username },
      { name = "KC_BOOTSTRAP_ADMIN_PASSWORD", value = var.admin_password }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.keycloak_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "keycloak"
      }
    }
  }])
}

# ==============================================================================
# ECS SERVICE
# ==============================================================================
resource "aws_ecs_service" "keycloak" {
  name            = "${var.project_name}-keycloak-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.keycloak.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id] 
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "keycloak"
    container_port   = 8080
  }
}