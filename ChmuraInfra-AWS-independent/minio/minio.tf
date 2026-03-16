resource "aws_cloudwatch_log_group" "minio_logs" {
  name              = "/ecs/${var.project_name}-minio"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "minio" {
  family                   = "${var.project_name}-minio"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  volume {
    name = "minio-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config { access_point_id = var.efs_access_point_id } 
    }
  }

  container_definitions = jsonencode([{
    name      = "minio"
    image     = "minio/minio:latest"
    essential = true
    
    command   = ["server", "/data", "--console-address", ":9001"]
    
    portMappings = [
      { containerPort = 9000 },
      { containerPort = 9001 } 
    ]

    environment = [
      { name = "MINIO_ROOT_USER",     value = var.minio_root_user },
      { name = "MINIO_ROOT_PASSWORD", value = var.minio_root_password },
      { name = "MINIO_PROMETHEUS_AUTH_TYPE", value = "public" }
    ]

    mountPoints = [{
      sourceVolume  = "minio-data"
      containerPath = "/data"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.minio_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "minio"
      }
    }
  }])
}

resource "aws_ecs_service" "minio" {
  name            = "${var.project_name}-minio-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.minio.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.minio_api_tg_arn
    container_name   = "minio"
    container_port   = 9000
  }

  load_balancer {
    target_group_arn = var.minio_console_tg_arn
    container_name   = "minio"
    container_port   = 9001
  }
}