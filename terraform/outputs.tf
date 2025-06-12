#########################################
# outputs.tf (root module)
#########################################

output "lambda_arn" {
  description = "ARN da função Lambda provisionada"
  value       = module.lambda.lambda_arn
}

output "lambda_function_name" {
  description = "Nome da função Lambda provisionada"
  value = module.lambda.lambda_function_name
}

output "bucket_name" {
  description = "Nome do bucket S3 onde está o código da Lambda"
  value       = data.aws_s3_bucket.lambda_code_bucket.bucket
}

# MODIFICADO: Output da URL da fila SQS (condicional)
output "sqs_queue_url" {
  description = "URL da fila SQS associada à Lambda (se criada)"
  # Utiliza a função 'try' para retornar "SQS not created" se o módulo SQS não for criado
  value       = try(module.sqs[0].queue_url, "SQS not created") # Adicionado '[0]' devido ao 'count'
}

# MODIFICADO: Output do ARN da fila SQS (condicional)
output "sqs_queue_arn" {
  description = "ARN da fila SQS associada à Lambda (se criada)"
  # Utiliza a função 'try' para retornar "SQS not created" se o módulo SQS não for criado
  value       = try(module.sqs[0].queue_arn, "SQS not created") # Adicionado '[0]' devido ao 'count'
}
