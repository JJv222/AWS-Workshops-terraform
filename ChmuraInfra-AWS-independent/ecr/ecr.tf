resource "aws_ecr_repository" "frontend" {
  name = "${lower(var.project_name)}-frontend"
  force_delete = true 
}

resource "aws_ecr_repository" "backend" {
  name = "${lower(var.project_name)}-backend"
  force_delete = true 
}

resource "aws_ecr_repository" "prometheus" {
  name = "${lower(var.project_name)}-prometheus"
  force_delete = true 
}

resource "aws_ecr_repository" "grafana" {
  name = "${lower(var.project_name)}-grafana"
  force_delete = true 
}