resource "aws_ecr_repository" "frontend" {
  name = "${lower(var.project_name)}-frontend"
}

resource "aws_ecr_repository" "backend" {
  name = "${lower(var.project_name)}-backend"
}