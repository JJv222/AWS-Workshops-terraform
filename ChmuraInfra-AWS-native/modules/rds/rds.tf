resource "aws_db_instance" "default" {
  allocated_storage    = var.db_allocated_storage
  db_name              = "${var.project_name}"
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.postgres.name
  skip_final_snapshot  = true
  vpc_security_group_ids = [ var.security_group_id ]
  port = var.db_port

  tags = {
    Name = "${var.project_name}-db"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when RDS CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "180"
  statistic           = "Average"
  threshold           = "1073741824"  # 1GB
  alarm_description   = "Alarm when RDS free storage is less than 1GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}
