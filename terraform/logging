# The Log Group
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = local.aws_cloudwatch_log_group_name
  retention_in_days = 7

  tags = local.common_tags
}

# API Gateway permission to write logs (Account-wide setting)
resource "aws_iam_role" "api_gw_cloudwatch" {
  name = local.aws_iam_role_cloudwatch_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gw_cloudwatch_attach" {
  role       = aws_iam_role.api_gw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Apply the role to API Gateway Account (Once per region)
resource "aws_api_gateway_account" "global" {
  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch.arn
}

# Enable Logging for the Stage
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.cell_dino_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = true # This shows the full request/response body
    metrics_enabled    = true
  }
}