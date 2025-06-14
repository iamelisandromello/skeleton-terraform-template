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

# MODIFICADO: Output da URL da fila SQS (condicional - apenas se a SQS for criada)
output "sqs_queue_url" {
  description = "URL da fila SQS associada à Lambda (se criada por este deploy)"
  value       = try(module.sqs[0].queue_url, "SQS not created by this deploy")
}

# MODIFICADO: Output do ARN da fila SQS (condicional - apenas se a SQS for criada)
output "sqs_queue_arn" {
  description = "ARN da fila SQS associada à Lambda (se criada por este deploy)"
  value       = try(module.sqs[0].queue_arn, "SQS not created by this deploy")
}

# NOVO: Output do ARN da fila SQS existente (se usada como trigger) - agora reflete o ARN RESOLVIDO
output "existing_sqs_trigger_arn" {
  description = "ARN da fila SQS existente usada como trigger para a Lambda (se aplicável)."
  # Referencia o ARN do data source se o trigger existente for usado, senão placeholder.
  value       = var.use_existing_sqs_trigger && var.existing_sqs_queue_name != "" ? data.aws_sqs_queue.existing_trigger_queue[0].arn : "No existing SQS queue used as trigger"
}
