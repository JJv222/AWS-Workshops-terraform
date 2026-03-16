# Logi
resource "aws_cloudwatch_log_group" "monitoring_logs" {
  name              = "/ecs/${var.project_name}-monitoring"
  retention_in_days = 7
}

# ==============================================================================
# 1. POSTGRES EXPORTER 
# ==============================================================================
resource "aws_ecs_task_definition" "pg_exporter" {
  family                   = "${var.project_name}-pg-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "postgres-exporter"
    image     = "prometheuscommunity/postgres-exporter"
    essential = true
    portMappings = [{ containerPort = 9187 }]
    environment = [
      { name = "DATA_SOURCE_URI",  value = "${var.internal_db_dns_name}:5432/postgres?sslmode=disable" },
      { name = "DATA_SOURCE_USER", value = var.db_username },
      { name = "DATA_SOURCE_PASS", value = var.db_password }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "pg-exporter"
      }
    }
  }])
}

resource "aws_ecs_service" "pg_exporter" {
  name            = "${var.project_name}-pg-exporter"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.pg_exporter.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.exporter_target_group_arn
    container_name   = "postgres-exporter"
    container_port   = 9187
  }
}

# ==============================================================================
# 2. PROMETHEUS
# ==============================================================================
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  volume {
    name = "prometheus-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = var.access_point_prometheus_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "prometheus"
    image     =  "${var.prometheus_repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 9090 }]
    
    mountPoints = [{
      sourceVolume  = "prometheus-data"
      containerPath = "/prometheus"
    }]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "prometheus"
      }
    }
  }])
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent = 100 
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.prometheus_tg_arn
    container_name   = "prometheus"
    container_port   = 9090
  }
}

# ==============================================================================
# 3. GRAFANA
# ==============================================================================
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  volume {
    name = "grafana-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.access_point_grafana_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = "${var.grafana_repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 3000 }]
    
    environment = [
      { name = "GF_SECURITY_ADMIN_USER",     value = "admin" },
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = var.grafana_password }
    ]

    mountPoints = [{
      sourceVolume  = "grafana-data"
      containerPath = "/var/lib/grafana"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "grafana"
      }
    }
  }])
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.grafana_tg_arn
    container_name   = "grafana"
    container_port   = 3000
  }
}