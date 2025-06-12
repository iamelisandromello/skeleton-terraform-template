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

# MODIFICADO: A política "lambda_sqs_publish" agora é condicional.
# Ela será criada (count = 1) SOMENTE se var.create_sqs_queue for true.
# Se var.create_sqs_queue for false, count será 0, e o recurso não será provisionado.
resource "aws_iam_role_policy" "lambda_sqs_publish" {
  count = var.create_sqs_queue ? 1 : 0 # O recurso será criado se 'create_sqs_queue' for true

  name = var.publish_policy_name
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["sqs:SendMessage"],
      # Quando o count é 1 (i.e., SQS está sendo criada), var.sqs_queue_arn terá um valor válido.
      # Se o count fosse 0, esta linha não seria avaliada, evitando o erro.
      Resource = var.sqs_queue_arn, 
      Effect   = "Allow"
    }]
  })
}
