# ==============================================================================
# LOGI (CloudWatch)
# ==============================================================================
resource "aws_cloudwatch_log_group" "db_logs" {
  name              = "/ecs/${var.project_name}-db"
  retention_in_days = 7
}

# ==============================================================================
# TASK DEFINITION (Postgres Container)
# ==============================================================================
resource "aws_ecs_task_definition" "db" {
  family                   = "${var.project_name}-db"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024 

  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  volume {
    name = "postgres-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id 
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "db"
    image     = "postgres:14"
    essential = true
    

    portMappings = [{
      containerPort = 5432
      protocol      = "tcp"
    }]

 
    environment = [
      { name = "POSTGRES_USER",     value = var.db_username },
      { name = "POSTGRES_PASSWORD", value = var.db_password },
      { name = "POSTGRES_DB",       value = "postgres" },
      { name = "PGDATA",            value = "/var/lib/postgresql/data/pgdata" }
    ]

 
    mountPoints = [{
      sourceVolume  = "postgres-data"
      containerPath = "/var/lib/postgresql/data"
    }]


    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.db_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "db"
      }
    }
  }])
}

# ==============================================================================
# ECS SERVICE (Uruchomienie i podpięcie pod NLB)
# ==============================================================================
resource "aws_ecs_service" "db" {
  name            = "${var.project_name}-db-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.db.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id] 
    assign_public_ip = true 
  }

  # (NLB)
  load_balancer {
    target_group_arn = var.db_target_group_arn
    container_name   = "db"
    container_port   = 5432
  }
}