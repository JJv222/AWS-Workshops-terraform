output "fronted_repository_url" {
   value = aws_ecr_repository.frontend.repository_url
}
output "backend_repository_url" {
   value = aws_ecr_repository.backend.repository_url
}
output "prometheus_repository_url" {
   value = aws_ecr_repository.prometheus.repository_url
}
output "grafana_repository_url" {
   value = aws_ecr_repository.grafana.repository_url
}