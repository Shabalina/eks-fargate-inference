locals {

  cluster_admins = toset([
    "arn:aws:iam::${var.root_user_id}:root",
    "arn:aws:iam::${var.root_user_id}:user/shabalinastya"
  ])



  # Standard tags to apply to everything for billing/organization
  common_tags = {
    Project     = "Cellular-Classification"
    Environment = var.env
    ManagedBy   = "Terraform"
    Owner       = "Data-Science-Team"
  }
}