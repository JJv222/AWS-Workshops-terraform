output "file_system_id" {
  value = aws_efs_file_system.main.id
}

output "access_point_postgres_id" {
  value = aws_efs_access_point.postgres.id
}

output "access_point_minio_id" {
  value = aws_efs_access_point.minio.id
}

output "access_point_prometheus_id" {
  value = aws_efs_access_point.prometheus.id
}

output "access_point_grafana_id" {
  value = aws_efs_access_point.grafana.id
}