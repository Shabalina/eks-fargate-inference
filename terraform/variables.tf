variable "env" {
  type        = string
  description = "The environment name (prod or qa)"
}
variable "region" {
  type        = string
  description = "AWS region"
}

variable "commit_sha" {
  type = string
}

variable "image_tag" {
  type        = string
  description = "latest"
}

variable "ecr_repo_name" {
  type        = string
  description = "name of the repository in ECR where the image is stored (e.g., cell-dino-repo)"
}

variable "ecr_url" {
  type        = string
  description = "The full URL of the ECR repository"
}
