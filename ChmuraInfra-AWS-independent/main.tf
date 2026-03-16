############################
# MODULES
############################

module "vpc" {
  source                     = "./vpc"
  project_name               = var.project_name
  vpc_cidr                   = var.vpc_cidr

  public_availability_zones  = var.availability_zones
  backend_availability_zone  = var.availability_zones[0]

  public_subnets             = var.public_subnets
  private_subnets            = var.private_subnets
  private_availability_zones = var.availability_zones
}

# --- PUBLIC ALB (HTTP/HTTPS) ---
# Frontend, Backend API, Keycloak, MinIO
module "alb" {
  source                   = "./alb"
  project_name             = var.project_name
  vpc_id                   = module.vpc.vpc_id

  frontend_port            = var.frontend_port 
  backend_port             = var.backend_port

  frontend_alb_subnets     = module.vpc.public_subnets
  frontend_security_groups = [aws_security_group.alb_sg.id]
}

# --- INTERNAL NLB (TCP) ---
resource "aws_lb" "internal_db" {
  name               = "${var.project_name}-db-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

# Listener dla bazy danych (TCP 5432)
resource "aws_lb_listener" "db_listener" {
  load_balancer_arn = aws_lb.internal_db.arn
  port              = "5432"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_tcp.arn 
  }
}


# 1. Target Group dla Postgres Exportera (TCP 9187)
resource "aws_lb_target_group" "db_exporter" {
  name        = "${var.project_name}-db-exporter-tg"
  port        = 9187
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  
  health_check {
    protocol = "TCP"
  }
}


resource "aws_lb_listener" "db_exporter_listener" {
  load_balancer_arn = aws_lb.internal_db.arn
  port              = "9187"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_exporter.arn
  }
}

resource "aws_lb_target_group" "db_tcp" {
  name        = "${var.project_name}-db-tg"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

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

module "ecr" {
  source       = "./ecr"
  project_name = var.project_name
}

module "efs" {
  source          = "./efs"
  creation_token  = var.project_name
  subnet_ids      = module.vpc.private_subnets
  security_groups = [aws_security_group.efs_sg.id] 
}


module "fargate" {
  source = "./fargate"

  project_name                = var.project_name
  vpc_id                      = module.vpc.vpc_id
  
  ecs_cluster_id              = aws_ecs_cluster.main.id 
  
  public_subnet_ids           = module.vpc.public_subnets
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn

  # Obrazy (z ECR)
  frontend_image              = module.ecr.fronted_repository_url
  backend_image               = module.ecr.backend_repository_url

  # Load Balancer & Routing
  frontend_tg_arn             = module.alb.frontend_tg_arn
  backend_tg_arn              = module.alb.backend_tg_arn
  frontend_sg_id              = aws_security_group.ecs_tasks_sg.id
  backend_sg_id               = aws_security_group.ecs_tasks_sg.id
  
  backend_url                 = "http://${module.alb.alb_dns_name}/api"

  alb_dns_name                = module.alb.alb_dns_name
  internal_db_dns_name        = aws_lb.internal_db.dns_name 
  
  db_username                 = var.db_username
  db_password                 = var.db_password
  
  minio_access_key            = "minioadmin"
  minio_secret_key            = "superTajneHaslo"
}

module "db_service" {
  source = "./db"

  project_name                = var.project_name
  aws_region                  = "us-east-1" # lub var.region
  
  ecs_cluster_id              = aws_ecs_cluster.main.id
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  
  # Sieć
  subnets                     = module.vpc.public_subnets
  security_group_id           = aws_security_group.ecs_tasks_sg.id
  
  # Storage
  efs_file_system_id          = module.efs.file_system_id
  efs_access_point_id          = module.efs.access_point_postgres_id
  
  # Load Balancer (NLB)
  db_target_group_arn         = aws_lb_target_group.db_tcp.arn
  
  # Dane
  db_username                 = var.db_username
  db_password                 = var.db_password
}


module "keycloak" {
  source = "./keycloak"

  project_name                = var.project_name
  ecs_cluster_id              = aws_ecs_cluster.main.id
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  
  # Sieć
  subnets                     = module.vpc.public_subnets
  security_group_id           = aws_security_group.ecs_tasks_sg.id

  # Obraz Keycloak
  keycloak_image_url          = "keycloak/keycloak:26.5" 

  # DNSy i Routing
  public_alb_dns_name         = module.alb.alb_dns_name 
  internal_db_dns_name        = aws_lb.internal_db.dns_name
  alb_target_group_arn        = module.alb.keycloak_tg_arn

  # Hasła
  db_username                 = var.db_username
  db_password                 = var.db_password
  admin_username              = "admin"
  admin_password              = "admin123"
}

module "minio" {
  source = "./minio"

  project_name                = var.project_name
  ecs_cluster_id              = aws_ecs_cluster.main.id
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  
  subnets                     = module.vpc.public_subnets
  security_group_id           = aws_security_group.ecs_tasks_sg.id
  
  efs_file_system_id          = module.efs.file_system_id
  
  minio_api_tg_arn            = module.alb.minio_api_tg_arn
  minio_console_tg_arn        = module.alb.minio_console_tg_arn
  
  minio_root_user             = "minioadmin"
  minio_root_password         = "superTajneHaslo"

  efs_access_point_id             = module.efs.access_point_minio_id
}

module "monitoring" {
  source = "./monitoring"

  project_name                = var.project_name
  ecs_cluster_id              = aws_ecs_cluster.main.id
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  
  subnets                     = module.vpc.public_subnets
  security_group_id           = aws_security_group.ecs_tasks_sg.id
  efs_file_system_id          = module.efs.file_system_id

  # Exporter potrzebuje dostępu do bazy
  internal_db_dns_name        = aws_lb.internal_db.dns_name
  db_username                 = var.db_username
  db_password                 = var.db_password
  
  # Load Balancer dla Grafany i Prometheusa
  grafana_tg_arn              = module.alb.grafana_tg_arn
  prometheus_tg_arn           = module.alb.prometheus_tg_arn
  
  grafana_password            = "admin"
  access_point_prometheus_id  = module.efs.access_point_prometheus_id
  access_point_grafana_id     = module.efs.access_point_grafana_id

  prometheus_repository_url   = module.ecr.prometheus_repository_url
  exporter_target_group_arn = aws_lb_target_group.db_exporter.arn

  grafana_repository_url      = module.ecr.grafana_repository_url
}

############################
# SECURITY GROUPS 
############################

# =======================
# 1. PUBLIC ALB SG
# =======================
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Public ALB Access (App, Keycloak, MinIO)"
  vpc_id      = module.vpc.vpc_id

  # Frontend / Backend API
  ingress {
    description = "HTTP Traffic (App)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Keycloak
  ingress {
    description = "Keycloak Traffic"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MinIO API
  ingress {
    description = "MinIO API"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MinIO Console
  ingress {
    description = "MinIO Console"
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # Grafana
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# =======================
# 2. ECS TASKS SG (ZBIORCZY)
# =======================
# Backend, Frontend, Postgres, Keycloak, MinIO
# =======================

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "All ECS Tasks Security Group"
  vpc_id      = module.vpc.vpc_id
  

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

 
  ingress {
    description = "Allow internal communication (Self)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }


  ingress {
    description = "Postgres Access for Internal NLB"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] 
  }


  ingress {
    description = "Postgres Exporter Access for Internal NLB"
    from_port   = 9187
    to_port     = 9187
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] 
  }

  egress {
    description = "Outbound all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =======================
# 3. EFS SG
# =======================
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS access from ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from ECS Tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}