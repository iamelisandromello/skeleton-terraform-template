#########################################
# main.tf (lambda module)
#########################################

resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key
  timeout       = 15

  environment {
    variables = var.environment_variables
  }
  
  # NOVO: Preconditions para garantir a lógica de SQS condicional
  lifecycle {
    precondition {
      # Validação de mutualidade exclusiva: create_sqs_queue e use_existing_sqs_trigger não podem ser true ao mesmo tempo.
      condition     = !(var.create_sqs_queue && var.use_existing_sqs_trigger)
      error_message = "As variáveis 'create_sqs_queue' e 'use_existing_sqs_trigger' não podem ser true ao mesmo tempo. Escolha apenas uma opção para SQS."
    }
    precondition {
      # Validação: existing_sqs_queue_arn deve ser fornecido se use_existing_sqs_trigger for true.
      condition     = var.use_existing_sqs_trigger ? (var.existing_sqs_queue_arn != "") : true
      error_message = "existing_sqs_queue_arn deve ser fornecido e não vazio se use_existing_sqs_trigger for true."
    }
  }
}
