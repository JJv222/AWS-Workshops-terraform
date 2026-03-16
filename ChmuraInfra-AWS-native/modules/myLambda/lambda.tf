data "aws_region" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/${var.project_name}-lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-myLambda"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudWatch logs
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },

      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.project_name}-myLambda"
  role             = var.role_arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DEST_PREFIX = var.dest_prefix
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]
}

# Pozwól S3 wywoływać lambdę
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

# Trigger S3 -> Lambda
resource "aws_s3_bucket_notification" "this" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
