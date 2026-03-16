variable "project_name" {
  type        = string
  description = "Prefix do nazw zasobów"
}

variable "bucket_name" {
  type        = string
  description = "Nazwa (lub id) bucketa S3, gdzie są wrzucane pliki"
}

variable "source_dir" {
  type        = string
  description = "Folder z kodem lambdy (np. lambda/). Musi zawierać lambda_function.py"
}

variable "role_arn" {
  type        = string
  description = "ARN istniejącej roli LabRole"
}

variable "role_name" {
  type        = string
  default     = "LabRole"
  description = "Nazwa roli (opcjonalnie). Jeśli null, wyciągniemy z ARN."
}


variable "handler" {
  type        = string
  description = "Handler lambdy"
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  type        = string
  description = "Runtime lambdy"
  default     = "python3.12"
}

variable "timeout" {
  type        = number
  default     = 10
}

variable "memory_size" {
  type        = number
  default     = 128
}

variable "dest_prefix" {
  type        = string
  description = "Docelowy prefix (folder) w S3"
  default     = "notepadApp/"
}

# Opcjonalne filtry triggera
variable "filter_prefix" {
  type        = string
  default     = ""
  description = "Prefix dla eventów S3 (np. uploads/). Pusty = wszystkie"
}

variable "filter_suffix" {
  type        = string
  default     = ""
  description = "Suffix dla eventów S3 (np. .png). Pusty = wszystkie"
}

variable "log_retention_days" {
  type        = number
  default     = 7
}
