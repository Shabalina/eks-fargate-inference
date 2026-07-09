# 1. The REST API
resource "aws_api_gateway_rest_api" "cell_dino_api" {
  name               = local.api_gateway_name
  binary_media_types = ["*/*"]

  tags = local.common_tags
}

# 2. The Resource (the path /predict)
resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.cell_dino_api.id
  parent_id   = aws_api_gateway_rest_api.cell_dino_api.root_resource_id
  path_part   = "predict"
}

# 3. The Method (POST)
resource "aws_api_gateway_method" "predict_post" {
  rest_api_id   = aws_api_gateway_rest_api.cell_dino_api.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "NONE" # Public

  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "sagemaker_200" {
  rest_api_id = aws_api_gateway_rest_api.cell_dino_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "sagemaker_200" {
  rest_api_id = aws_api_gateway_rest_api.cell_dino_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  status_code = aws_api_gateway_method_response.sagemaker_200.status_code

  # Tells API Gateway to treat SageMaker's 200 as an API 200
  selection_pattern = "^2[0-9][0-9]$"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  depends_on = [aws_api_gateway_integration.sagemaker_link]
}

# 4. The Integration with SageMaker
resource "aws_api_gateway_integration" "sagemaker_link" {
  rest_api_id             = aws_api_gateway_rest_api.cell_dino_api.id
  resource_id             = aws_api_gateway_resource.predict.id
  http_method             = aws_api_gateway_method.predict_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  # The URI format is specific for SageMaker:
  uri = "arn:aws:apigateway:${var.region}:runtime.sagemaker:path/endpoints/${aws_sagemaker_endpoint.cell_dino_endpoint.name}/invocations"

  credentials = aws_iam_role.apigw_sagemaker_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

# 5. Deployment & Stage
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.cell_dino_api.id

  depends_on = [
    aws_api_gateway_integration.sagemaker_link,
    aws_api_gateway_method.predict_post
  ]

  # Forces a redeployment whenever the settings change
  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_resource.predict.id,
      aws_api_gateway_method.predict_post.id,
      aws_api_gateway_integration.sagemaker_link.id,
      aws_api_gateway_integration.sagemaker_link.uri, # Track the URI specifically
      aws_api_gateway_integration.sagemaker_link.integration_http_method,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.cell_dino_api.id
  stage_name    = "prod"
}