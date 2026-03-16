// modules/cognito/main.tf
data "aws_region" "current" {}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.project_name}-domain"
  user_pool_id = aws_cognito_user_pool.this.id
}

locals {
  region = data.aws_region.current.name

  hosted_ui_base_url = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${local.region}.amazoncognito.com"

  scope_string = join("+", var.allowed_oauth_scopes)

  default_redirect_uri = var.callback_url
  default_logout_uri   = var.logout_url
}
resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  # OIDC / Authorization Code Flow
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = var.allowed_oauth_scopes

  callback_urls = [var.callback_url]
  logout_urls   = [var.logout_url]

  supported_identity_providers = ["COGNITO"]

  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
resource "aws_cognito_user" "seed_user_jj222" {
  user_pool_id = aws_cognito_user_pool.this.id
  username = "263855@student.pwr.edu.pl"
  password = "Aa12345!"
  enabled = true

   message_action = "SUPPRESS"
}

// Przydatne lokalne wartości do OUTPUTÓW
# locals {
#   region = data.aws_region.current.name

#   hosted_ui_base_url = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${local.region}.amazoncognito.com"

#   scope_string = join("+", var.allowed_oauth_scopes)

#   default_redirect_uri = try(var.callback_urls[0], "")
#   default_logout_uri   = try(var.logout_urls[0], local.default_redirect_uri)

#   login_url = "${local.hosted_ui_base_url}/login?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=${urlencode(local.scope_string)}&redirect_uri=${urlencode(local.default_redirect_uri)}"

#   logout_url = "${local.hosted_ui_base_url}/logout?client_id=${aws_cognito_user_pool_client.this.id}&logout_uri=${urlencode(local.default_logout_uri)}"
# }

locals {
  login_url = "${local.hosted_ui_base_url}/login?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=${urlencode(local.scope_string)}&redirect_uri=${urlencode(local.default_redirect_uri)}"

  logout_url = "${local.hosted_ui_base_url}/logout?client_id=${aws_cognito_user_pool_client.this.id}&logout_uri=${urlencode(local.default_logout_uri)}"
}