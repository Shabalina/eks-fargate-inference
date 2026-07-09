terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-sha"
    key            = "eks-sandbox/terraform.tfstate" 
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


# data "aws_ecr_image" "latest_image" {
#   repository_name = var.ecr_repo_name
#   image_tag       = var.image_tag # e.g., "qa"
# }
