locals {

  sagemaker_endpoint_name = "cell-dino-serverless-endpoint-${var.env}"

  aws_iam_role_sagemaker_name   = "apigw-sagemaker-invocation-role-${var.env}"
  aws_iam_policy_sagemaker_name = "apigw-sagemaker-invocation-policy-${var.env}"

  api_gateway_name = "cell-dino-public-api-${var.env}"

  aws_cloudwatch_log_group_name = "/aws/api-gateway/cell-dino-api-${var.env}"
  aws_iam_role_cloudwatch_name  = "api-gw-cloudwatch-global-${var.env}"
  streamlit_url                 = "https://shabalina-cell-dino-api-uiapp-uqmv5v.streamlit.app/"




  # Standard tags to apply to everything for billing/organization
  common_tags = {
    Project     = "Cellular-Classification"
    Environment = var.env
    ManagedBy   = "Terraform"
    Owner       = "Data-Science-Team"
  }
}