#########################################
# main.tf (iam module)
#########################################

resource "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })
}

resource "aws_iam_role_policy" "lambda_logging_policy" {
  name = var.logging_policy_name
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      Resource = "*",
      Effect   = "Allow"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_sqs_publish" {
  name = var.publish_policy_name
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["sqs:SendMessage"],
      Resource = var.sqs_queue_arn,
      Effect   = "Allow"
    }]
  })
}