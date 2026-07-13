variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., prod)"
  default     = "prod"
}

variable "root_user_id" {
  type        = string
  description = "The AWS account ID of the root user"
}