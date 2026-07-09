# The Role
resource "aws_iam_role" "apigw_sagemaker_role" {
  name = local.aws_iam_role_sagemaker_name

  # Allows the API Gateway service to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# 2. The Permission Policy
resource "aws_iam_role_policy" "apigw_sagemaker_policy" {
  name = local.aws_iam_policy_sagemaker_name
  role = aws_iam_role.apigw_sagemaker_role.id

  # Allows the role to call sagemaker endpoint
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sagemaker:InvokeEndpoint"
        Effect   = "Allow"
        Resource = aws_sagemaker_endpoint.cell_dino_endpoint.arn
      }
    ]
  })
}