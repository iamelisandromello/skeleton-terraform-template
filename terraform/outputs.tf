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

output "sqs_queue_url" {
  description = "URL da fila SQS associada à Lambda"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila SQS associada à Lambda"
  value       = module.sqs.queue_arn
}
