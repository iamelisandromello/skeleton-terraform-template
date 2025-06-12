#########################################
# variables.tf (iam module)
#########################################

variable "lambda_role_name" {
  description = "Nome da role IAM para a função Lambda"
  type        = string
}

variable "logging_policy_name" {
  description = "Nome da política IAM para logs da Lambda"
  type        = string
}

variable "publish_policy_name" {
  description = "Nome da política IAM para publicação em SQS"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN da fila SQS para permissões de publicação. Pode ser 'SQS not created' se a fila não for criada."
  type        = string
}

# NOVO: Variável para controlar a criação condicional da política SQS
variable "create_sqs_queue" {
  description = "Define se a fila SQS (e, portanto, sua política de publicação) deve ser criada."
  type        = bool
  default     = true # O padrão é true para manter o comportamento existente
}
