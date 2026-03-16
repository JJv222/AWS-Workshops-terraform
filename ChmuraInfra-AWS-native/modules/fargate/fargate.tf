# Security Group dla Load Balancera
data "aws_region" "current" {}
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# Frontend ECS Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn             = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      memory    = 512
      portMappings = [
        {
          containerPort = var.frontend_port
          hostPort      = var.frontend_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_BASE_URL"
          value = var.backend_url
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
          "awslogs-stream-prefix" = "frontend"
          "awslogs-region"        = data.aws_region.current.name
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-frontend-td"
  }
}

# Backend ECS Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn             = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      memory    = 512
      portMappings = [
        {
          containerPort = var.backend_port
          hostPort      = var.backend_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "SPRING_DATASOURCE_URL",      value = var.connection_string },
        { name = "SPRING_DATASOURCE_USERNAME", value = var.db_username },
        { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password },
        { name = "AWS.S3.BUCKET", value = var.s3_name},
        { name = "AWS.S3.PREFIX", value = "notepadApp"}, //same as in lambda_function.py file
        { name = "COGNITO_ISSUER_URI", value = var.cognit_issuer_url },
        { name = "COGNITO_CLIENT_ID", value = var.cognito_client_id },
        { name = "COGNITO_REGION", value = data.aws_region.current.name},
        { name = "COGNITO_SCOPES", value = join(" ", var.cognito_scopes) },
        { name = "COGNITO_REDIRECT_URL", value =  var.cognito_redirect_url},
        { name = "COGNITO_LOGOUT_URL", value = var.cognito_logout_url}
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
          "awslogs-stream-prefix" = "backend"
          "awslogs-region"        = data.aws_region.current.name
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-backend-td"
  }
}

# Frontend ECS Service
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups = [var.frontend_sg_id]
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }


  tags = {
    Name = "${var.project_name}-frontend-service"
  }
}

# Backend ECS Service
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups = [var.backend_sg_id]
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn   
    container_name   = "backend"
    container_port   = var.backend_port
  }


  tags = {
    Name = "${var.project_name}-backend-service"
  }
}

###LOGI
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend"
  retention_in_days = 7 
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend"
  retention_in_days = 7
}
