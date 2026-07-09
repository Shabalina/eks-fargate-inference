terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-sha"
    key            = "sagemaker/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Standardises to the latest version 5
    }
    # KEEP THIS TEMPORARILY to fix the error
    # archive = {
    #   source  = "hashicorp/archive"
    #   version = "~> 2.0"
    # }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_ecr_image" "latest_image" {
  repository_name = var.ecr_repo_name
  image_tag       = var.image_tag # e.g., "qa"
}
# resource "random_id" "model_suffix" {
#   byte_length = 4
#   keepers = {
#     # .id is the sha256 digest
#     image_digest = data.aws_ecr_image.latest_image.id
#   }
# }

# # 1. Model
# resource "aws_sagemaker_model" "cell_dino_model" {
#   name               = "cell-dino-model-${random_id.model_suffix.hex}"
#   execution_role_arn = var.sagemaker_role_arn

#   primary_container {
#     # image = "${var.ecr_url}:${var.image_tag}"
#     image = "${var.ecr_url}@${data.aws_ecr_image.latest_image.id}" 
#   }
#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = local.common_tags
# }

# # 2. Endpoint Configuration (Serverless settings)
# resource "aws_sagemaker_endpoint_configuration" "cell_dino_config" {
#   name = "cell-dino-config-${random_id.model_suffix.hex}"

#   production_variants {
#     variant_name = "AllTraffic"
#     model_name   = aws_sagemaker_model.cell_dino_model.name

#     serverless_config {
#       max_concurrency   = 5
#       memory_size_in_mb = 3072
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = local.common_tags
# }

# # 3. The Endpoint (The permanent address)
# resource "aws_sagemaker_endpoint" "cell_dino_endpoint" {
#   name                 = "${local.sagemaker_endpoint_name}-${random_id.model_suffix.hex}"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.cell_dino_config.name

#   lifecycle {
#     # replace_triggered_by = [
#     #   aws_sagemaker_endpoint_configuration.cell_dino_config.name
#     # ]
#     ignore_changes = [tags]
#   }

#   depends_on = [aws_sagemaker_endpoint_configuration.cell_dino_config]

#   tags = local.common_tags
# }