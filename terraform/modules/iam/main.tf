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
# Isso se aplica apenas se a SQS estiver sendo criada NESTE deploy.
resource "aws_iam_role_policy" "lambda_sqs_publish" {
  count = var.create_sqs_queue ? 1 : 0 

  name = var.publish_policy_name
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["sqs:SendMessage"],
      Resource = var.sqs_queue_arn, # var.sqs_queue_arn virá da nova fila, se criada
      Effect   = "Allow"
    }]
  })
}

# NOVO: Política para permitir que a Lambda consuma de uma fila SQS existente
# Este recurso será criado (count = 1) SOMENTE se var.use_existing_sqs_trigger for true.
resource "aws_iam_role_policy" "lambda_sqs_consume" {
  count = var.use_existing_sqs_trigger ? 1 : 0 # Criar política se a flag for true

  name = var.consume_policy_name
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        # Resource será o ARN da fila SQS existente que foi passado
        Resource = var.existing_sqs_queue_arn,
        Effect   = "Allow"
      }
    ]
  })
}
