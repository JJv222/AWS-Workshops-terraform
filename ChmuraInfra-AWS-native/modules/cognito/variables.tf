// modules/cognito/variables.tf
variable "project_name" {
  type        = string
  description = "Nazwa projektu (prefiks do user poola, domeny itd.)"
}

variable "callback_url" {
  type        = string
}

variable "logout_url" {
  type        = string
}

variable "allowed_oauth_scopes" {
  type        = list(string)
  description = "Scopes dla OIDC"
  default     = ["openid", "email", "phone"]
}
