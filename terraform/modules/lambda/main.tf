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
  
  # A associação do trigger (aws_lambda_event_source_mapping) será feita no módulo raiz (main.tf),
  # pois o módulo Lambda deve ser genérico e não "saber" sobre todos os seus triggers.
  # No entanto, a Lambda pode precisar de permissões para o SQS.
}
