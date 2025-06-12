#########################################
# variables.tf (iam module)
#########################################

variable "lambda_role_name" {
  description = "Nome da IAM Role de execução da Lambda"
  type        = string
}

variable "logging_policy_name" {
  description = "Nome da policy de logs da Lambda"
  type        = string
}

variable "publish_policy_name" {
  description = "Nome da policy que publica na SQS"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN da fila SQS"
  type        = string
}
