output "id" {
    value       = aws_s3_bucket.bucket.id
    description = "ID of the S3 bucket"
}
output "bucket_name"{
    value       = aws_s3_bucket.bucket.bucket
    description = "Name of the S3 bucket"
}