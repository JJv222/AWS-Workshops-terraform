############################
# MODULES
############################

module "vpc" {
  source                     = "./modules/vpc"
  project_name               = var.project_name
  vpc_cidr                   = var.vpc_cidr

  public_availability_zones  = var.availability_zones
  backend_availability_zone  = var.availability_zones[0]

  public_subnets             = var.public_subnets
  private_subnets            = var.private_subnets
  private_availability_zones = var.availability_zones
}

module "alb" {
  source                   = "./modules/alb"
  project_name             = var.project_name
  vpc_id                   = module.vpc.vpc_id

  frontend_port            = var.frontend_port     # najlepiej 80
  backend_port             = var.backend_port      # np. 8080

  frontend_alb_subnets     = module.vpc.public_subnets
  frontend_security_groups = [aws_security_group.frontend_alb.id]
  # backend ALB już NIE MA
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "rds" {
  source               = "./modules/rds"
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  private_subnets_ids  = module.vpc.private_subnets
  security_group_id    = aws_security_group.rds_access.id
  db_username          = var.db_username
  db_password          = var.db_password
  db_port              = var.db_port
}

module "fargate" {
  source                      = "./modules/fargate"
  project_name                = var.project_name
  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnets

  # jeśli u Ciebie output nazywa się inaczej niż bucket_name → podmień
  s3_name                     = module.s3.bucket_name

  connection_string           = module.rds.jdbc_url
  db_username                 = var.db_username
  db_password                 = var.db_password

  # DODAJ TAGI obrazów w tfvars / modułach!
  frontend_image              = module.ecr.fronted_repository_url
  backend_image               = module.ecr.backend_repository_url

  frontend_port               = var.frontend_port
  backend_port                = var.backend_port

  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn

  frontend_tg_arn             = module.alb.frontend_tg_arn
  backend_tg_arn              = module.alb.backend_tg_arn

  # przy 1 ALB najlepsze:
  backend_url                 = "/api"

  frontend_sg_id              = aws_security_group.frontend_fargate.id
  backend_sg_id               = aws_security_group.backend_fargate.id

  cognit_issuer_url = module.cognito.authority
  cognito_client_id = module.cognito.client_id
  cognito_scopes = module.cognito.scopes
  cognito_redirect_url = module.cognito.login_url
  cognito_logout_url = module.cognito.logout_url

  depends_on = [ module.cognito ]
}

module "cognito" {
  source       = "./modules/cognito"
  project_name = var.project_name
  callback_url = "https://${module.alb.alb_dns}"
  logout_url   = "https://${module.alb.alb_dns}"
}


module "myLambda" {
  source       = "./modules/myLambda"
  project_name = "notatnik" 
  bucket_name  = module.s3.bucket_name

  # folder z lambda_function.py
  source_dir   = "./modules/myLambda/code"
  role_arn = var.ecs_task_execution_role_arn
}


############################
# SECURITY GROUPS
############################

# =======================
# PUBLIC FRONTEND ALB SG
# =======================
resource "aws_security_group" "frontend_alb" {
  name        = "frontend_alb_sg"
  description = "Public ALB for frontend"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Internet do ALB"
    from_port   = var.frontend_port   # najlepiej 80
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ALB to targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================
# FRONTEND FARGATE SG
# =====================
resource "aws_security_group" "frontend_fargate" {
  name        = "frontend_fargate_sg"
  description = "Frontend tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "ALB do frontend tasks"
    from_port       = var.frontend_port
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }

  egress {
    description = "Frontend do Internet/Backend"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ====================
# BACKEND FARGATE SG
# ====================
resource "aws_security_group" "backend_fargate" {
  name        = "backend_fargate_sg"
  description = "Backend tasks - only ALB can reach"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "ALB do backend tasks (/api)"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }

  egress {
    description = "Backend do Internet (ECR etc.) + RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =============
# RDS ACCESS SG
# =============
resource "aws_security_group" "rds_access" {
  name        = "${var.project_name}-rds-access-sg"
  description = "Allows backend tasks to access RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Backend tasks do RDS"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_fargate.id]
  }

  egress {
    description = "RDS outbound allow-all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
