data "aws_region" "current" {}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 7
}

# ==============================================================================
# FRONTEND TASK DEFINITION
# ==============================================================================
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_image
    essential = true
    portMappings = [{
      containerPort = var.frontend_port
      protocol      = "tcp"
    }]
    environment = [
      { name = "API_BASE_URL", value = var.backend_url }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
        "awslogs-stream-prefix" = "frontend"
        "awslogs-region"        = data.aws_region.current.name
      }
    }
  }])
}

# ==============================================================================
# BACKEND TASK DEFINITION (TUTAJ NAJWIĘKSZE ZMIANY)
# ==============================================================================
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = var.backend_image
    essential = true
    
    portMappings = [{
      containerPort = var.backend_port
      protocol      = "tcp"
    }]

    # ODZWOROWANIE DOCKER-COMPOSE
    environment = [
      { name = "SPRING_APPLICATION_NAME", value = "SimpleNotatnik" },

      # --- KEYCLOAK ---
      { name = "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI", 
        value = "http://${var.alb_dns_name}:8081/realms/simple-notatnik" },
      
      { name = "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI", 
        value = "http://${var.alb_dns_name}:8081/realms/simple-notatnik/protocol/openid-connect/certs" },

      # --- DATABASE ---
      # Docker: DB_HOST: db
      { name = "DB_HOST",     value = var.internal_db_dns_name },
      { name = "DB_PORT",     value = "5432" },
      { name = "DB_NAME",     value = "postgres" },
      { name = "DB_USER",     value = var.db_username },
      { name = "DB_PASSWORD", value = var.db_password },

      # --- MINIO ---
      { name = "MINIO_URL",        value = "http://${var.alb_dns_name}:9000" },
      { name = "MINIO_ACCESS_KEY", value = var.minio_access_key },
      { name = "MINIO_SECRET_KEY", value = var.minio_secret_key },
      { name = "MINIO_BUCKET",     value = var.minio_bucket },
      { name = "MINIO_PREFIX",     value = "notepad" },
      { name = "MINIO_SECURE",     value = "false" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
        "awslogs-stream-prefix" = "backend"
        "awslogs-region"        = data.aws_region.current.name
      }
    }
  }])
}

# ==============================================================================
# SERVICES
# ==============================================================================

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups  = [var.frontend_sg_id]
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups  = [var.backend_sg_id]
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn   
    container_name   = "backend"
    container_port   = var.backend_port
  }
}