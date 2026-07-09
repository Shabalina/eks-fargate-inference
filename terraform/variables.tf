variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., prod)"
  default     = "prod"
}
