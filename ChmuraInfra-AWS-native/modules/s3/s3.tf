
resource "aws_s3_bucket" "bucket" {
  bucket = "${lower(var.project_name)}-bucket-ja263855"

  tags = {
    Name        = "${var.project_name}-s3-bucket"
  }
}