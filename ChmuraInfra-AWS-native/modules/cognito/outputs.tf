// modules/cognito/outputs.tf
output "user_pool_id" {
  value       = aws_cognito_user_pool.this.id
}

output "client_id" {
  value       = aws_cognito_user_pool_client.this.id
}

output "authority" {
  description = "Authority/ "
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "login_url" {
  value       = local.login_url
}

output "logout_url" {
  value       = local.logout_url
}

output "scopes" {
  value = var.allowed_oauth_scopes
}
